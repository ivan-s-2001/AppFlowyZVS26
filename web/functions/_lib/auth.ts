export interface Env {
  DB: D1Database;
  GROUP_CODE: string;
}

export function authorized(request: Request, env: Env): boolean {
  const cookie = request.headers.get("Cookie") || "";
  const match = cookie.match(/(?:^|;\s*)zvs26_auth=([^;]+)/);
  return Boolean(match && decodeURIComponent(match[1]) === env.GROUP_CODE);
}

export function unauthorized(): Response {
  return new Response(JSON.stringify({ error: "unauthorized" }), {
    status: 401,
    headers: { "Content-Type": "application/json" },
  });
}

export function json(data: unknown, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json; charset=utf-8");
  return new Response(JSON.stringify(data), { ...init, headers });
}
