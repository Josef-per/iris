import assert from "node:assert/strict";
import test from "node:test";
import { loadEdgeRuntime } from "../_shared/edge_test_runtime.ts";

const validOutput = {
  needsHumanSupport: false,
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
  let modelNeedsSupport = false;
  const moods: unknown[] = [];
  const preferences = { personalizacao_ativa: true, fontes_consentidas: ["diary_text", "mood_history"], fuso_horario: "UTC" };
  const admin = {
    auth: { getUser: () => ({ data: { user: { id: "user" } }, error: null }) },
    from(table: string) {
      const query = {
        filters: {} as Record<string, unknown>,
        select() { return query; },
        eq(key: string, value: unknown) { query.filters[key] = value; return query; },
        gt() { return query; },
        maybeSingle() {
          const tables: Record<string, unknown> = {
            pacientes: { id: "patient" }, preferencias_ia_apoio: preferences,
            rollout_ia_apoio: { apoio_ativo: true, mensagem_diaria_ativa: true, openai_ativa: true, kill_switch: false, modo: "limited", modelo: "gpt-5-mini", percentual_entrega: 100 },
            registros_emocionais: record,
            mensagens_diarias_ia: cached?.versao_prompt === query.filters.versao_prompt ? cached : null,
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
      if (modelNeedsSupport) return response({ needsHumanSupport: true, title: null, introduction: null, points: null });
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
  assert.equal(updated.functionVersion, "daily-companion-v7");
  assert.deepEqual(moods, [null, "steady", "steady"]);

  cached!.versao_prompt = "daily-companion-v4";
  assert.equal((await load()).status, "ready");
  assert.equal(calls, 4, "cache antigo e regenerado com o contrato atual");

  cached!.mensagem = "Uma introdução completa para começar.\n\n- **Agora:** Até sentir-se mais equilibrado emocional-";
  const recovered = await load();
  assert.equal(recovered.status, "ready");
  assert.ok(!recovered.message.includes("emocional-"));
  assert.equal(calls, 5, "cache cortado e regenerado mesmo com a versao atual");

  record.diario_emocional = "Estou pensando em me matar.";
  assert.equal((await load()).status, "needs_human_support");
  assert.equal(calls, 5, "crise explicita tem prioridade mesmo se houver cache");

  record.diario_emocional = "Texto fictício sem os termos do filtro local.";
  cached = null;
  modelNeedsSupport = true;
  const support = await load();
  assert.equal(support.status, "needs_human_support");
  assert.equal(support.reflectionQuestion, null);
  assert.equal(calls, 6, "encaminhamento pelo modelo nao dispara nova geracao");
  assert.equal(cached, null, "encaminhamento humano nao vira reflexao em cache");
});

test("recusa explicita do modelo nao e repetida nem exibe texto acompanhante", async () => {
  let calls = 0;
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch() {
      calls++;
      return Response.json({ status: "completed", output: [{ content: [
        { type: "refusal", refusal: "recusa fictícia" },
        { type: "output_text", text: JSON.stringify(validOutput) },
      ] }] });
    },
  });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(calls, 1);
  assert.equal(result.message, null);
  assert.equal(result.reasonCode, "model_refusal");
});

test("aceita frases completas acima do limite antigo sem cortar o texto", async () => {
  const output = {
    ...validOutput,
    introduction: "Pode ser que você esteja buscando segurança e algum alívio imediato após uma situação difícil.",
    points: [
      { label: "Uma prioridade possível", text: "Talvez reconhecer o que precisa de atenção neste momento ajude a organizar as escolhas, enquanto as decisões menos urgentes podem esperar até que suas necessidades estejam mais claras." },
      { label: "Apoio disponível", text: "Pode ser útil considerar quais pessoas da sua rede de apoio conhecem o que você está vivendo e com quem você se sentiria à vontade para conversar sobre suas necessidades neste momento." },
    ],
  };
  const runtime = loadEdgeRuntime("ai-daily-companion", { fetch() { return response(output); } });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(result.reasonCode, "accepted");
  assert.ok(result.message.message.length > 480);
  for (const point of output.points) assert.ok(result.message.message.includes(point.text));
});

test("repete trechos cortados ou com reticencias e preserva a frase completa", async () => {
  for (const fragment of [
    "Decisões sociais podem esperar até sentir-se mais equilibrado emocional-",
    "Talvez valha notar o cansaço; priorizar algo que recarregue,",
    "Se houver risco atual, considerar contactar serviços de emergência ou alguém de confiança para estar fisically",
    "Talvez buscar informar um profissional, amigo próximo e tbm",
    "Talvez seja possível considerar...",
    "Talvez seja possível considerar…",
  ]) {
    for (const field of ["introduction", "text"]) {
      let calls = 0;
      const runtime = loadEdgeRuntime("ai-daily-companion", {
        fetch() {
          calls++;
          return response(calls > 1 ? validOutput : {
            ...validOutput,
            ...(field === "introduction" ? { introduction: fragment } : { points: [{ label: "Agora", text: fragment }] }),
          });
        },
      });
      const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
      assert.equal(calls, 2);
      assert.equal(result.reasonCode, "accepted");
      assert.ok(!result.message.message.includes(fragment));
    }
  }
});

test("cache com trecho cortado e rejeitado antes de chegar ao aplicativo", async () => {
  const runtime = loadEdgeRuntime("ai-daily-companion");
  const introduction = "Uma introdução completa para começar.";
  const completePoint = "- **Agora:** Uma frase completa para encerrar.";
  let message = `${introduction}\n\n${completePoint}`;
  const admin = {
    from() {
      const query = {
        select() { return query; }, eq() { return query; }, gt() { return query; },
        maybeSingle() {
          return { data: { titulo: "Uma reflexão para hoje", mensagem: message, pergunta_reflexao: null }, error: null };
        },
      };
      return query;
    },
  };
  assert.equal((await runtime.findExistingMessage(admin, "patient", "2026-09-10")).message, message);
  for (const fragment of [
    "Decisões sociais podem esperar até sentir-se mais equilibrado emocional-",
    "Talvez valha notar o cansaço; priorizar algo que recarregue,",
    "Uma possibilidade que ainda precisa ser",
    "Talvez seja possível considerar...",
    "Talvez seja possível considerar…",
  ]) {
    for (const broken of [
      `${fragment}\n\n${completePoint}`,
      `${introduction}\n\n- **Agora:** ${fragment}`,
      `${introduction}\n\n- **Agora:** ${fragment}\n- **Depois:** Uma frase completa para encerrar.`,
    ]) {
      message = broken;
      assert.equal(await runtime.findExistingMessage(admin, "patient", "2026-09-10"), null, broken);
    }
  }
});

test("sinalizacao de apoio humano prevalece sobre texto acompanhante invalido", async () => {
  let calls = 0;
  const runtime = loadEdgeRuntime("ai-daily-companion", {
    fetch() { calls++; return response({ ...validOutput, needsHumanSupport: true, introduction: "Cortado" }); },
  });
  const result = await runtime.generateMessage({ context, model: "gpt-5-mini" });
  assert.equal(calls, 1);
  assert.equal(result.message, null);
  assert.equal(result.reasonCode, "needs_human_support");
});
