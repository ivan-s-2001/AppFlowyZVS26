import { Env, authorized, json, unauthorized } from "../../_lib/auth";

type Row = {
  id: string;
  parent_id: string | null;
  title: string;
  content_json: string;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

const normalize = (row: Row) => ({
  ...row,
  content: JSON.parse(row.content_json || "[]"),
  content_json: undefined,
});

export const onRequestPut: PagesFunction<Env, "id"> = async ({ request, env, params }) => {
  if (!authorized(request, env)) return unauthorized();

  const body = await request.json<{ title?: string; content?: unknown[]; parent_id?: string | null }>().catch(() => ({}));
  const existing = await env.DB.prepare("SELECT id FROM pages WHERE id = ?").bind(params.id).first();
  if (!existing) return json({ error: "not_found" }, { status: 404 });

  if (typeof body.title === "string") {
    await env.DB.prepare("UPDATE pages SET title = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
      .bind(body.title.trim() || "Без названия", params.id).run();
  }
  if (Array.isArray(body.content)) {
    await env.DB.prepare("UPDATE pages SET content_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
      .bind(JSON.stringify(body.content), params.id).run();
  }
  if ("parent_id" in body) {
    await env.DB.prepare("UPDATE pages SET parent_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
      .bind(body.parent_id || null, params.id).run();
  }

  const row = await env.DB.prepare(
    "SELECT id, parent_id, title, content_json, sort_order, created_at, updated_at FROM pages WHERE id = ?"
  ).bind(params.id).first<Row>();
  return json(normalize(row!));
};

export const onRequestDelete: PagesFunction<Env, "id"> = async ({ request, env, params }) => {
  if (!authorized(request, env)) return unauthorized();

  const protectedIds = new Set(["home", "semester-1", "sessions", "teachers", "archive"]);
  if (protectedIds.has(String(params.id))) return json({ error: "protected" }, { status: 409 });

  const ids = [String(params.id)];
  for (let i = 0; i < ids.length; i++) {
    const children = await env.DB.prepare("SELECT id FROM pages WHERE parent_id = ?").bind(ids[i]).all<{ id: string }>();
    ids.push(...(children.results || []).map((x) => x.id));
  }

  const placeholders = ids.map(() => "?").join(",");
  await env.DB.prepare(`DELETE FROM pages WHERE id IN (${placeholders})`).bind(...ids).run();
  return json({ ok: true });
};
