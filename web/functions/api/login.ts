import { Env, json } from "../_lib/auth";

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  const body = await request.json<{ code?: string }>().catch(() => ({}));
  const code = (body.code || "").trim().toUpperCase();

  if (!env.GROUP_CODE || code !== env.GROUP_CODE.toUpperCase()) {
    return json({ ok: false }, { status: 401 });
  }

  return json(
    { ok: true },
    {
      headers: {
        "Set-Cookie": `zvs26_auth=${encodeURIComponent(env.GROUP_CODE)}; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=31536000`,
      },
    },
  );
};
