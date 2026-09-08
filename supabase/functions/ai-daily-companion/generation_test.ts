import assert from "node:assert/strict";
import test from "node:test";
import { loadEdgeRuntime } from "../_shared/edge_test_runtime.ts";

const validOutput = {
  title: "Uma prioridade possível",
  introduction: "Talvez uma prioridade pequena ajude a organizar o que merece atenção hoje.",
  points: [{ label: "Agora", text: "Uma escolha possível pode ser suficiente por enquanto." }],
};
const context = {
  sources: ["diary_text", "mood_history"], record: null,
  mood: "steady", topics: [], diaryText: "Registro fictício de teste.",
};
function response(output: unknown, status = "completed") {
  return Response.json({ status, output: [{ content: [{ type: "output_text", text: JSON.stringify(output) }] }] });
}

test("repete resposta invalida apos atualizar humor e aceita somente conteudo validado", async () => {
  const bodies: Record<string, any>[] = [];
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch(_url: string, init: RequestInit) {
      bodies.push(JSON.parse(init.body as string));
      return response(bodies.length === 1 ? { ...validOutput, introduction: "Curta" } : validOutput);
    },
  });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(bodies.length, 2);
  assert.equal(result.reasonCode, "accepted");
  assert.match(result.message.message, /\*\*Agora:\*\*/);
  assert.deepEqual(bodies[0], bodies[1]);
  assert.equal(bodies[0].store, false);
});

test("limita tentativas e devolve causa tecnica sem texto de diario", async () => {
  let calls = 0;
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch() { calls++; return response({ ...validOutput, points: [] }); },
  });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(calls, 2);
  assert.equal(result.message, null);
  assert.equal(result.reasonCode, "model_output_invalid");
  assert.ok(!JSON.stringify(result).includes(context.diaryText));
});

test("resposta incompleta nunca e exibida e falha de autenticacao nao e repetida", async () => {
  for (const httpStatus of [401, 429]) {
    let calls = 0;
    const runtime = loadEdgeRuntime("ai-daily-companion", {
      fetch() { calls++; return new Response(null, { status: httpStatus }); },
    });
    const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
    assert.equal(calls, 1);
    assert.equal(result.message, null);
  }
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch() { return response(validOutput, "incomplete"); },
  });
  assert.equal((await runtime.generateMessage({ context, model: "gpt-5-mini" })).reasonCode, "model_incomplete");
});

test("timeout pode se recuperar sem aceitar conteudo proibido", async () => {
  let calls = 0;
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch() {
      calls++;
      if (calls === 1) throw new Error("temporary_network_failure");
      return response({ ...validOutput, introduction: "Talvez seja útil reduzir contato com a família por alguns dias." });
    },
  });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(calls, 2);
  assert.equal(result.message, null);
  assert.equal(result.reasonCode, "model_output_invalid");
});

test("ler diario autorizado nao inclui humor sem consentimento", async () => {
  const runtime = loadEdgeRuntime("ai-daily-companion");
  const admin = {
    from() {
      const query = {
        select() { return query; }, eq() { return query; },
        maybeSingle() { return { data: { diario_emocional: "Registro fictício.", como_sentiu: 3 }, error: null }; },
      };
      return query;
    },
  };
  const loaded = await runtime.loadContext(admin, "patient", "2026-09-08", { fontes_consentidas: ["diary_text"] });
  assert.equal(loaded.mood, null);
  assert.equal(loaded.diaryText, "Registro fictício.");
  assert.equal(JSON.stringify(loaded.sources), '["diary_text"]');
});

test("handler recupera reflexao depois de diario, cache e alteracao de humor", async () => {
  let handler: (request: Request) => Promise<Response>;
  let record: Record<string, unknown> | null = null;
  let cached: Record<string, unknown> | null = null;
  let calls = 0;
  const moods: unknown[] = [];
  const preferences = { personalizacao_ativa: true, fontes_consentidas: ["diary_text", "mood_history"], fuso_horario: "UTC" };
  const admin = {
    auth: { getUser: () => ({ data: { user: { id: "user" } }, error: null }) },
    from(table: string) {
      const query = {
        select() { return query; }, eq() { return query; }, gt() { return query; },
        maybeSingle() {
          const tables: Record<string, unknown> = {
            pacientes: { id: "patient" }, preferencias_ia_apoio: preferences,
            rollout_ia_apoio: { apoio_ativo: true, mensagem_diaria_ativa: true, openai_ativa: true, kill_switch: false, modo: "limited", modelo: "gpt-5-mini", percentual_entrega: 100 },
            registros_emocionais: record, mensagens_diarias_ia: cached,
          };
          assert.ok(Object.hasOwn(tables, table), table);
          return { data: tables[table], error: null };
        },
        upsert(value: Record<string, unknown>) { cached = value; return query; },
        single() { return { data: cached, error: null }; },
      };
      return query;
    },
  };
  const env: Record<string, string> = {
    SUPABASE_URL: "https://supabase.invalid", SUPABASE_ANON_KEY: "test-public",
    SUPABASE_SERVICE_ROLE_KEY: "test-secret", OPENAI_API_KEY: "test-api-key",
  };
  loadEdgeRuntime("ai-daily-companion", {
    createClient: () => admin,
    Deno: { serve(value: typeof handler) { handler = value; }, env: { get(key: string) { return env[key]; } } },
    fetch(_url: string, init: RequestInit) {
      calls++;
      moods.push(JSON.parse(JSON.parse(init.body as string).input).mood);
      return response(calls === 2 ? { ...validOutput, points: [] } : validOutput);
    },
  });
  async function load() {
    return (await handler(new Request("https://function.invalid", {
      method: "POST", headers: { Authorization: "Bearer test-session" }, body: "{}",
    }))).json();
  }
  assert.equal((await load()).status, "waiting_for_context");
  record = { id: "record", diario_emocional: "Registro fictício.", como_sentiu: null };
  assert.equal((await load()).status, "ready");
  assert.equal((await load()).status, "ready");
  assert.equal(calls, 1, "consulta em cache nao chama o modelo");
  record.como_sentiu = 3;
  cached = null; // mesmo efeito da migration 0013 ao salvar o check-in
  const updated = await load();
  assert.equal(updated.status, "ready");
  assert.equal(updated.functionVersion, "daily-companion-v5");
  assert.deepEqual(moods, [null, "steady", "steady"]);
});
