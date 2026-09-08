import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import vm from "node:vm";
import * as cors from "./cors.ts";

// Executa o handler real com fronteiras substituidas. Nenhum teste pode
// acessar a rede ou iniciar um servidor Deno por acidente.
export function loadEdgeRuntime(name: string, overrides: Record<string, unknown> = {}) {
  const source = readFileSync(new URL(`../${name}/index.ts`, import.meta.url), "utf8")
    .replace(/^import[\s\S]*?;\n/gm, "");
  const runtime = vm.createContext({
    ...cors,
    Request, Response, AbortController, URL, TextEncoder, crypto,
    setTimeout, clearTimeout,
    console: { error() {} },
    fetch() { throw new Error("network_not_mocked"); },
    Deno: {
      serve(handler: unknown) { runtime.handler = handler; },
      env: { get() { return "test-secret"; } },
    },
    ...overrides,
  });
  vm.runInContext(stripTypeScriptTypes(source, { mode: "transform" }), runtime);
  return runtime;
}
