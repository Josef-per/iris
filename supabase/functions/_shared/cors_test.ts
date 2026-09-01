import { corsHeadersFor } from "./cors.ts";

Deno.test("development allows Flutter Web on a random localhost port", () => {
  const headers = corsHeadersFor(
    "http://localhost:56501",
    undefined,
    "development",
  );

  if (headers["Access-Control-Allow-Origin"] !== "http://localhost:56501") {
    throw new Error("localhost origin was not allowed in development");
  }
  const allowedHeaders = headers["Access-Control-Allow-Headers"]
    .split(",")
    .map((value) => value.trim().toLowerCase());
  if (!allowedHeaders.includes("x-client-info")) {
    throw new Error("Supabase client info header was not allowed");
  }
});

Deno.test("production still requires an explicitly configured origin", () => {
  const headers = corsHeadersFor(
    "http://localhost:56501",
    "https://app.example.com",
    "production",
  );

  if (headers["Access-Control-Allow-Origin"] !== undefined) {
    throw new Error("localhost origin was unexpectedly allowed in production");
  }
});

Deno.test("configured origins are allowed in every environment", () => {
  const headers = corsHeadersFor(
    "https://app.example.com",
    "https://other.example.com, https://app.example.com",
    "production",
  );

  if (headers["Access-Control-Allow-Origin"] !== "https://app.example.com") {
    throw new Error("configured origin was not allowed");
  }
});
