export function corsHeadersFor(
  origin: string | null,
  allowedOriginsValue: string | undefined,
  environmentValue: string | undefined,
): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers":
      "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Cache-Control": "no-store",
    Vary: "Origin",
  };
  if (origin === null) return headers;

  const allowedOrigins = new Set(
    (allowedOriginsValue ?? "")
      .split(",")
      .map((value) => value.trim())
      .filter((value) => value !== ""),
  );
  const isDevelopment = environmentValue === "development";
  if (allowedOrigins.has(origin) || (isDevelopment && isLoopbackOrigin(origin))) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

function isLoopbackOrigin(origin: string): boolean {
  try {
    const url = new URL(origin);
    return url.protocol === "http:" &&
      (url.hostname === "localhost" ||
        url.hostname === "127.0.0.1" ||
        url.hostname === "[::1]");
  } catch {
    return false;
  }
}
