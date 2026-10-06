import { Env, authorized, json, unauthorized } from "../_lib/auth";

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

export const onRequestGet: PagesFunction<Env> = async ({ request, env }) => {
  if (!authorized(request, env)) return unauthorized();

  const result = await env.DB.prepare(
    "SELECT id, parent_id, title, content_json, sort_order, created_at, updated_at FROM pages ORDER BY sort_order, title"
  ).all<Row>();

  return json({ pages: (result.results || []).map(normalize) });
};

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  if (!authorized(request, env)) return unauthorized();

  const body = await request.json<{ title?: string; parent_id?: string | null }>().catch(() => ({}));
  const id = crypto.randomUUID();
  const title = (body.title || "Новая страница").trim() || "Новая страница";
  const parentId = body.parent_id || null;
  const max = await env.DB.prepare(
    "SELECT COALESCE(MAX(sort_order), 0) AS max_order FROM pages WHERE parent_id IS ?"
  ).bind(parentId).first<{ max_order: number }>();
  const sortOrder = Number(max?.max_order || 0) + 10;

  await env.DB.prepare(
    "INSERT INTO pages (id, parent_id, title, content_json, sort_order) VALUES (?, ?, ?, '[]', ?)"
  ).bind(id, parentId, title, sortOrder).run();

  const row = await env.DB.prepare(
    "SELECT id, parent_id, title, content_json, sort_order, created_at, updated_at FROM pages WHERE id = ?"
  ).bind(id).first<Row>();

  return json(normalize(row!), { status: 201 });
};
