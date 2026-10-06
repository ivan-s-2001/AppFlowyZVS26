import { Env, json } from "../_lib/auth";

export const onRequestPost: PagesFunction<Env> = async () =>
  json(
    { ok: true },
    { headers: { "Set-Cookie": "zvs26_auth=; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0" } },
  );
