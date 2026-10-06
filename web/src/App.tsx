import { useCallback, useEffect, useMemo, useState } from "react";
import { useCreateBlockNote } from "@blocknote/react";
import { BlockNoteView } from "@blocknote/mantine";

type Page = {
  id: string;
  parent_id: string | null;
  title: string;
  content: unknown[];
  sort_order: number;
  created_at: string;
  updated_at: string;
};

async function api<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    ...init,
    headers: { "Content-Type": "application/json", ...(init?.headers || {}) },
  });
  if (res.status === 401) throw new Error("UNAUTHORIZED");
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

function Login({ onLogin }: { onLogin: () => void }) {
  const [code, setCode] = useState("");
  const [error, setError] = useState("");

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    try {
      await api("/api/login", { method: "POST", body: JSON.stringify({ code }) });
      onLogin();
    } catch {
      setError("Неверный код");
    }
  };

  return (
    <main className="login-screen">
      <form className="login-card" onSubmit={submit}>
        <div className="brand-mark">ЗВС<span>-26</span></div>
        <h1>База знаний группы</h1>
        <p>Предметы, ДКР, материалы, преподаватели и всё важное — в одном месте.</p>
        <input
          autoFocus
          value={code}
          onChange={(e) => setCode(e.target.value.toUpperCase())}
          placeholder="Код группы"
          autoCapitalize="characters"
          autoCorrect="off"
        />
        {error && <div className="error">{error}</div>}
        <button type="submit">Войти</button>
      </form>
    </main>
  );
}

function Editor({ page, onSaved }: { page: Page; onSaved: (page: Page) => void }) {
  const editor = useCreateBlockNote({
    initialContent: Array.isArray(page.content) && page.content.length ? page.content as any : undefined,
  });
  const [title, setTitle] = useState(page.title);
  const [status, setStatus] = useState<"saved" | "saving">("saved");

  const save = useCallback(async (nextTitle = title) => {
    setStatus("saving");
    const updated = await api<Page>(`/api/pages/${page.id}`, {
      method: "PUT",
      body: JSON.stringify({ title: nextTitle.trim() || "Без названия", content: editor.document }),
    });
    setStatus("saved");
    onSaved(updated);
  }, [page.id, title, editor, onSaved]);

  useEffect(() => {
    const handler = setTimeout(() => save(), 900);
    return () => clearTimeout(handler);
  }, [title, editor.document]);

  return (
    <section className="editor-pane">
      <div className="editor-topline">
        <input
          className="page-title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onBlur={() => save()}
        />
        <span className="save-status">{status === "saving" ? "Сохраняю…" : "Сохранено"}</span>
      </div>
      <BlockNoteView editor={editor} onChange={() => setStatus("saving")} theme="dark" />
    </section>
  );
}

function Tree({
  pages,
  activeId,
  onSelect,
}: {
  pages: Page[];
  activeId: string | null;
  onSelect: (id: string) => void;
}) {
  const children = useMemo(() => {
    const map = new Map<string | null, Page[]>();
    for (const page of pages) {
      const key = page.parent_id;
      const arr = map.get(key) || [];
      arr.push(page);
      map.set(key, arr);
    }
    for (const arr of map.values()) arr.sort((a, b) => a.sort_order - b.sort_order || a.title.localeCompare(b.title));
    return map;
  }, [pages]);

  const render = (parent: string | null, depth = 0): JSX.Element[] =>
    (children.get(parent) || []).flatMap((page) => [
      <button
        key={page.id}
        className={`tree-item ${activeId === page.id ? "active" : ""}`}
        style={{ paddingLeft: 12 + depth * 16 }}
        onClick={() => onSelect(page.id)}
      >
        <span>{page.title}</span>
      </button>,
      ...render(page.id, depth + 1),
    ]);

  return <nav className="tree">{render(null)}</nav>;
}

export default function App() {
  const [auth, setAuth] = useState<"loading" | "in" | "out">("loading");
  const [pages, setPages] = useState<Page[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const load = useCallback(async () => {
    try {
      const data = await api<{ pages: Page[] }>("/api/pages");
      setPages(data.pages);
      setAuth("in");
      if (!activeId && data.pages.length) setActiveId(data.pages.find((p) => p.id === "home")?.id || data.pages[0].id);
    } catch (e) {
      if ((e as Error).message === "UNAUTHORIZED") setAuth("out");
    }
  }, [activeId]);

  useEffect(() => { load(); }, []);

  const active = pages.find((p) => p.id === activeId) || null;
  const visible = query.trim()
    ? pages.filter((p) => p.title.toLowerCase().includes(query.toLowerCase()))
    : pages;

  const createPage = async () => {
    const page = await api<Page>("/api/pages", {
      method: "POST",
      body: JSON.stringify({ title: "Новая страница", parent_id: activeId }),
    });
    setPages((old) => [...old, page]);
    setActiveId(page.id);
    setSidebarOpen(false);
  };

  const deletePage = async () => {
    if (!active || ["home", "semester-1", "sessions", "teachers", "archive"].includes(active.id)) return;
    if (!confirm(`Удалить «${active.title}» и вложенные страницы?`)) return;
    await api(`/api/pages/${active.id}`, { method: "DELETE" });
    setActiveId("home");
    await load();
  };

  if (auth === "loading") return <div className="boot">ЗВС-26</div>;
  if (auth === "out") return <Login onLogin={load} />;

  return (
    <div className="app-shell">
      <aside className={`sidebar ${sidebarOpen ? "open" : ""}`}>
        <div className="sidebar-header">
          <div className="brand">ЗВС<span>-26</span></div>
          <button className="icon-btn close-mobile" onClick={() => setSidebarOpen(false)}>×</button>
        </div>
        <div className="search-wrap">
          <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Поиск" />
        </div>
        <Tree
          pages={visible}
          activeId={activeId}
          onSelect={(id) => { setActiveId(id); setSidebarOpen(false); }}
        />
        <div className="sidebar-actions">
          <button onClick={createPage}>＋ Страница</button>
          <button className="secondary" onClick={() => api("/api/logout", { method: "POST" }).then(() => setAuth("out"))}>
            Выйти
          </button>
        </div>
      </aside>

      <main className="content">
        <header className="mobile-header">
          <button className="icon-btn" onClick={() => setSidebarOpen(true)}>☰</button>
          <div className="brand small">ЗВС<span>-26</span></div>
          <button className="icon-btn" onClick={createPage}>＋</button>
        </header>
        {active ? (
          <>
            <Editor
              key={active.id}
              page={active}
              onSaved={(updated) => setPages((old) => old.map((p) => p.id === updated.id ? updated : p))}
            />
            <button className="danger" onClick={deletePage}>Удалить страницу</button>
          </>
        ) : (
          <div className="empty">Выбери страницу</div>
        )}
      </main>

      {sidebarOpen && <button className="scrim" aria-label="Закрыть меню" onClick={() => setSidebarOpen(false)} />}
    </div>
  );
}
