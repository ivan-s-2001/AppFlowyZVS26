interface Env {
  CLOUD_ORIGIN: string;
  GOTRUE_ORIGIN: string;
  SUPABASE_ANON_KEY: string;
}

function joinOrigin(origin: string, pathname: string, search: string): URL {
  const target = new URL(origin);
  const basePath = target.pathname.replace(/\/$/, "");
  target.pathname = `${basePath}${pathname.startsWith("/") ? pathname : `/${pathname}`}`;
  target.search = search;
  return target;
}

function cors(response: Response, request: Request): Response {
  const headers = new Headers(response.headers);
  const origin = request.headers.get("Origin");
  if (origin) {
    headers.set("Access-Control-Allow-Origin", origin);
    headers.set("Vary", "Origin");
  }
  headers.set("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    request.headers.get("Access-Control-Request-Headers") ||
      "authorization,content-type,apikey,x-client-info",
  );
  headers.set("Access-Control-Max-Age", "86400");

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const incoming = new URL(request.url);

    if (incoming.pathname === "/gateway-health") {
      return Response.json({
        ok: true,
        service: "zvs26-cloud-gateway",
      });
    }

    if (request.method === "OPTIONS") {
      return cors(new Response(null, { status: 204 }), request);
    }

    const isGoTrue =
      incoming.pathname === "/gotrue" ||
      incoming.pathname.startsWith("/gotrue/");

    let target: URL;
    const headers = new Headers(request.headers);

    if (isGoTrue) {
      const authPath = incoming.pathname.replace(/^\/gotrue/, "") || "/";
      target = joinOrigin(env.GOTRUE_ORIGIN, authPath, incoming.search);

      // Supabase's hosted GoTrue requires an apikey header even though the
      // upstream AppFlowy client talks to a plain GoTrue-compatible endpoint.
      if (env.SUPABASE_ANON_KEY) {
        headers.set("apikey", env.SUPABASE_ANON_KEY);
      }
    } else {
      target = joinOrigin(env.CLOUD_ORIGIN, incoming.pathname, incoming.search);
    }

    headers.delete("host");

    const upstreamRequest = new Request(target, {
      method: request.method,
      headers,
      body:
        request.method === "GET" || request.method === "HEAD"
          ? undefined
          : request.body,
      redirect: "manual",
    });

    const response = await fetch(upstreamRequest);

    // WebSocket upgrades must be returned untouched.
    if (response.webSocket) {
      return response;
    }

    return cors(response, request);
  },
};
