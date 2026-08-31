import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

import {
  buildSelectionSchema,
  eligibleTemplates,
  extractStructuredOutput,
  localSelection,
  supportCategories,
  supportSources,
  type AcceptedSelection,
  type DailyCheckIn,
  type InteractionSummary,
  type MoodTrend,
  type SelectionContext,
  type SupportCategory,
  type SupportSource,
  type SupportTrigger,
  type TopicKey,
  validateSelection,
} from "../_shared/ai_support_contract.ts";

const openAiResponsesUrl = "https://api.openai.com/v1/responses";
const allowedTriggers = new Set([
  "manual",
  "after_checkin",
  "after_diary",
  "notification_open",
]);
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const selectionInstructions = `
Voce e um componente de roteamento de apoio, nao um terapeuta.
Escolha no maximo um ID permitido ou abstenha-se.
Use somente os sinais estruturados e codigos fornecidos.
Use PREFERRED_FROM_PAST_INTERACTIONS apenas como complemento de outro motivo.
Use PREFERS_SHORT_PRACTICE apenas como complemento de um sinal de check-in.
Nao diagnostique, nao estime risco, nao afirme causas e nao produza texto para a pessoa.
Nao recomende alimentacao, peso, atividade fisica, medicacao ou tratamento.
Nao escolha contato, horario ou envio de notificacao.
Quando a evidencia for insuficiente ou houver conflito, escolha abstain.
Retorne somente o objeto exigido pelo schema.
`.trim();

type RequestBody = {
  requestId: string;
  trigger: string;
};

type RolloutMode = "local" | "shadow" | "pilot" | "limited";

type RolloutConfiguration = {
  ambiente: string;
  apoio_ativo: boolean;
  modo: RolloutMode;
  openai_ativa: boolean;
  kill_switch: boolean;
  percentual_shadow: number;
  percentual_entrega: number;
  modelo: string | null;
  versao_prompt: string;
  versao_catalogo: string;
};

type PreferencesRow = {
  personalizacao_ativa: boolean;
  fontes_consentidas: string[];
  categorias_permitidas: string[];
  duracao_maxima_minutos: number;
  conteudos_excluidos: string[];
  fuso_horario: string;
  pausado_ate: string | null;
};

type CheckInRow = {
  data_local: string;
  fuso_horario: string | null;
  como_sentiu: number | null;
};

type TopicRow = {
  topico: string;
  confirmado_em: string | null;
};

type EventRow = {
  tipo: string;
  canal: string;
  sugestao_id: string | null;
  ocorrido_em: string;
};

type SuggestionRow = {
  id: string;
  template_id: string | null;
  categoria: string | null;
  exercicio_id: string | null;
  criado_em: string;
};

type ModelAttempt = {
  selection: AcceptedSelection | null;
  result: "sugerida" | "silencio" | "rejeitada" | "erro";
  validationCode: string;
  outputHash: string | null;
  latencyMs: number;
  inputTokens: number | null;
  outputTokens: number | null;
};

type PersistRunInput = {
  patientId: string;
  requestId: string;
  trigger: string;
  role: "efetiva" | "shadow";
  mode: RolloutMode;
  origin: "regra_local" | "openai" | "fallback";
  selection: AcceptedSelection | null;
  result: "sugerida" | "silencio" | "rejeitada" | "erro";
  promptVersion: string;
  catalogVersion: string;
  model: string | null;
  validationCode: string;
  outputHash?: string | null;
  latencyMs?: number | null;
  inputTokens?: number | null;
  outputTokens?: number | null;
};

Deno.serve(async (request) => {
  const origin = request.headers.get("Origin");
  const corsHeaders = corsHeadersFor(origin);
  if (request.method === "OPTIONS") {
    if (origin !== null && corsHeaders["Access-Control-Allow-Origin"] === undefined) {
      return jsonResponse(403, { code: "ORIGIN_NOT_ALLOWED" });
    }
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { code: "METHOD_NOT_ALLOWED" }, corsHeaders);
  }
  if (origin !== null && corsHeaders["Access-Control-Allow-Origin"] === undefined) {
    return jsonResponse(403, { code: "ORIGIN_NOT_ALLOWED" });
  }

  let body: RequestBody;
  try {
    body = parseRequestBody(await request.json());
  } catch {
    return jsonResponse(400, { code: "INVALID_REQUEST" }, corsHeaders);
  }

  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return jsonResponse(401, { code: "AUTH_REQUIRED" }, corsHeaders);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
  const publishableKey = readSupabaseKey(
    "SUPABASE_PUBLISHABLE_KEYS",
    "SUPABASE_ANON_KEY",
  );
  const secretKey = readSupabaseKey(
    "SUPABASE_SECRET_KEYS",
    "SUPABASE_SERVICE_ROLE_KEY",
  );
  if (supabaseUrl === "" || publishableKey === "" || secretKey === "") {
    auditLog("server_configuration_missing", body.requestId);
    return jsonResponse(503, { code: "SUPPORT_TEMPORARILY_UNAVAILABLE" }, corsHeaders);
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError !== null || userData.user === null) {
    return jsonResponse(401, { code: "AUTH_INVALID" }, corsHeaders);
  }

  const admin = createClient(supabaseUrl, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  try {
    const patientId = await findPatientId(admin, userData.user.id);
    if (patientId === null) {
      return jsonResponse(403, { code: "PATIENT_REQUIRED" }, corsHeaders);
    }

    const previous = await findEffectiveRun(admin, patientId, body.requestId);
    if (previous !== null) {
      return jsonResponse(200, responseForRun(previous), corsHeaders);
    }

    const environment = normalizedEnvironment(
      Deno.env.get("AI_SUPPORT_ENVIRONMENT"),
    );
    const [rollout, preferences] = await Promise.all([
      loadRollout(admin, environment),
      loadPreferences(admin, patientId),
    ]);

    await recordServerEvent(admin, {
      patientId,
      suggestionId: null,
      clientEventId: body.requestId,
      type: "solicitada",
    });

    if (
      !rollout.apoio_ativo ||
      preferences === null ||
      !preferences.personalizacao_ativa ||
      isPaused(preferences.pausado_ate)
    ) {
      const row = await persistRun(admin, {
        patientId,
        requestId: body.requestId,
        trigger: body.trigger,
        role: "efetiva",
        mode: rollout.modo,
        origin: "regra_local",
        selection: null,
        result: "silencio",
        promptVersion: rollout.versao_prompt,
        catalogVersion: rollout.versao_catalogo,
        model: null,
        validationCode: "support_disabled_or_not_consented",
      });
      return jsonResponse(200, responseForRun(row), corsHeaders);
    }

    const context = await buildContext(
      admin,
      patientId,
      preferences,
      body.trigger as SupportTrigger,
    );
    const local = localSelection(context);
    const safetySalt = Deno.env.get("AI_SUPPORT_SAFETY_SALT")?.trim() ?? "";
    const configuredModel = Deno.env.get("OPENAI_MODEL")?.trim() ?? "";
    const canUseModel =
      rollout.openai_ativa &&
      !rollout.kill_switch &&
      eligibleTemplates(context).length > 0 &&
      local !== null &&
      configuredModel !== "" &&
      safetySalt !== "" &&
      rollout.modelo === configuredModel;

    let shouldCallModel = false;
    if (canUseModel && rollout.modo === "shadow") {
      shouldCallModel =
        (await stableBucket(patientId, safetySalt, "shadow")) <
        rollout.percentual_shadow;
    } else if (canUseModel && rollout.modo === "pilot") {
      shouldCallModel = await isActivePilotParticipant(admin, patientId);
    } else if (canUseModel && rollout.modo === "limited") {
      shouldCallModel =
        (await stableBucket(patientId, safetySalt, "limited")) <
        rollout.percentual_entrega;
    }

    let attempt: ModelAttempt | null = null;
    if (shouldCallModel) {
      attempt = await requestModelSelection({
        context,
        patientId,
        model: configuredModel,
        promptVersion: rollout.versao_prompt,
        safetySalt,
      });
    }

    if (rollout.modo === "shadow" && attempt !== null) {
      await persistRun(admin, {
        patientId,
        requestId: body.requestId,
        trigger: body.trigger,
        role: "shadow",
        mode: rollout.modo,
        origin: "openai",
        selection: attempt.selection,
        result: attempt.result,
        promptVersion: rollout.versao_prompt,
        catalogVersion: rollout.versao_catalogo,
        model: configuredModel,
        validationCode: attempt.validationCode,
        outputHash: attempt.outputHash,
        latencyMs: attempt.latencyMs,
        inputTokens: attempt.inputTokens,
        outputTokens: attempt.outputTokens,
      });
    }

    const modelCanBeVisible =
      attempt?.selection !== null &&
      attempt?.selection !== undefined &&
      (rollout.modo === "pilot" || rollout.modo === "limited");
    const effectiveSelection = modelCanBeVisible ? attempt!.selection : local;
    const modelFailedBeforeFallback =
      attempt !== null && attempt.selection === null && rollout.modo !== "shadow";
    const origin = modelCanBeVisible
      ? "openai"
      : modelFailedBeforeFallback
      ? "fallback"
      : "regra_local";
    const validationCode = modelCanBeVisible
      ? attempt!.validationCode
      : modelFailedBeforeFallback
      ? `fallback_after_${attempt!.validationCode}`
      : shouldCallModel
      ? "shadow_not_visible"
      : rollout.kill_switch
      ? "kill_switch_local"
      : "local_policy";

    const effectiveRow = await persistRun(admin, {
      patientId,
      requestId: body.requestId,
      trigger: body.trigger,
      role: "efetiva",
      mode: rollout.modo,
      origin,
      selection: effectiveSelection,
      result: effectiveSelection === null ? "silencio" : "sugerida",
      promptVersion: rollout.versao_prompt,
      catalogVersion: rollout.versao_catalogo,
      model: modelCanBeVisible ? configuredModel : null,
      validationCode,
      outputHash: modelCanBeVisible ? attempt!.outputHash : null,
      latencyMs: modelCanBeVisible ? attempt!.latencyMs : null,
      inputTokens: modelCanBeVisible ? attempt!.inputTokens : null,
      outputTokens: modelCanBeVisible ? attempt!.outputTokens : null,
    });
    await recordServerEvent(admin, {
      patientId,
      suggestionId: effectiveRow.id,
      clientEventId: crypto.randomUUID(),
      type: "gerada",
    });

    return jsonResponse(200, responseForRun(effectiveRow), corsHeaders);
  } catch {
    auditLog("unhandled_support_error", body.requestId);
    return jsonResponse(503, { code: "SUPPORT_TEMPORARILY_UNAVAILABLE" }, corsHeaders);
  }
});

async function buildContext(
  admin: SupabaseClient,
  patientId: string,
  preferences: PreferencesRow,
  trigger: SupportTrigger,
): Promise<SelectionContext> {
  const sources = preferences.fontes_consentidas.filter(
    (value): value is SupportSource =>
      (supportSources as readonly string[]).includes(value) &&
      value !== "exercise_feedback",
  );
  const categories = preferences.categorias_permitidas.filter(
    (value): value is SupportCategory =>
      (supportCategories as readonly string[]).includes(value) &&
      (value === "reflection" || value === "exercise"),
  );
  const now = new Date();
  const thirtyDaysAgo = new Date(
    now.getTime() - 30 * 24 * 60 * 60 * 1000,
  ).toISOString();
  const oneDayAgo = new Date(
    now.getTime() - 24 * 60 * 60 * 1000,
  ).toISOString();

  const checkInsPromise = sources.includes("mood_history")
    ? admin
        .from("registros_emocionais")
        .select("data_local,fuso_horario,como_sentiu")
        .eq("paciente_id", patientId)
        .not("como_sentiu", "is", null)
        .order("data_local", { ascending: false })
        .limit(4)
    : Promise.resolve({ data: [], error: null });
  const topicsPromise = sources.includes("diary_topics")
    ? admin
        .from("topicos_apoio")
        .select("topico,confirmado_em")
        .eq("paciente_id", patientId)
        .eq("estado", "confirmado")
        .is("invalidado_em", null)
        .gt("expira_em", now.toISOString())
        .order("confirmado_em", { ascending: false })
        .limit(10)
    : Promise.resolve({ data: [], error: null });
  const eventsPromise =
    sources.includes("notification_interactions") ||
      sources.includes("exercise_feedback")
      ? admin
          .from("eventos_ia_apoio")
          .select("tipo,canal,sugestao_id,ocorrido_em")
          .eq("paciente_id", patientId)
          .gte("ocorrido_em", thirtyDaysAgo)
          .order("ocorrido_em", { ascending: false })
          .limit(100)
      : Promise.resolve({ data: [], error: null });
  const suggestionsPromise = admin
    .from("sugestoes_ia_apoio")
    .select("id,template_id,categoria,exercicio_id,criado_em")
    .eq("paciente_id", patientId)
    .eq("papel", "efetiva")
    .eq("resultado", "sugerida")
    .gte("criado_em", thirtyDaysAgo)
    .order("criado_em", { ascending: false })
    .limit(50);

  const [checkInsResult, topicsResult, eventsResult, suggestionsResult] =
    await Promise.all([
      checkInsPromise,
      topicsPromise,
      eventsPromise,
      suggestionsPromise,
    ]);
  if (
    checkInsResult.error !== null ||
    topicsResult.error !== null ||
    eventsResult.error !== null ||
    suggestionsResult.error !== null
  ) {
    throw new Error("context_query_failed");
  }

  const checkIns = (checkInsResult.data ?? []) as CheckInRow[];
  const topics = (topicsResult.data ?? []) as TopicRow[];
  const events = (eventsResult.data ?? []) as EventRow[];
  const suggestions = (suggestionsResult.data ?? []) as SuggestionRow[];
  const suggestionById = new Map(
    suggestions.map((suggestion) => [suggestion.id, suggestion]),
  );

  return {
    schemaVersion: "1",
    trigger,
    allowedCategories: categories,
    maximumExerciseMinutes: preferences.duracao_maxima_minutos,
    excludedContentTags: [...preferences.conteudos_excluidos],
    consentedSources: sources,
    dailyCheckIn: dailyCheckInFor(
      checkIns,
      now,
      preferences.fuso_horario,
    ),
    moodTrend: moodTrendFor(checkIns),
    confirmedTopics: confirmedTopicsFor(topics),
    interactions: interactionSummaryFor(events, suggestionById, sources),
    recentTemplateIds: suggestions
      .filter((suggestion) => suggestion.criado_em >= oneDayAgo)
      .map((suggestion) => suggestion.template_id)
      .filter((value): value is string => value !== null),
  };
}

function moodTrendFor(checkIns: CheckInRow[]): MoodTrend | null {
  const scores = checkIns
    .map((row) => row.como_sentiu)
    .filter((score): score is number => Number.isInteger(score))
    .filter((score) => score >= 1 && score <= 5);
  if (scores.length < 4) return null;
  const difficult = scores.filter((score) => score <= 2).length;
  const direction = difficult >= 3
    ? "difficult"
    : scores[0] > scores[scores.length - 1]
    ? "easier"
    : "stable";
  return {
    direction,
    difficultCheckInCount: difficult,
    sampleSize: scores.length,
    windowDays: 7,
  };
}

function dailyCheckInFor(
  checkIns: CheckInRow[],
  now: Date,
  fallbackTimeZone: string,
): DailyCheckIn | null {
  const today = checkIns.find((row) =>
    row.data_local === localIsoDate(
      now,
      row.fuso_horario ?? fallbackTimeZone,
    )
  );
  const score = today?.como_sentiu;
  if (
    typeof score !== "number" ||
    !Number.isInteger(score) ||
    score < 1 ||
    score > 5
  ) {
    return null;
  }
  return {
    moodBand: score <= 2 ? "difficult" : score === 3 ? "steady" : "lighter",
  };
}

function confirmedTopicsFor(rows: TopicRow[]): TopicKey[] {
  const allowed = new Set<TopicKey>([
    "overload",
    "loneliness",
    "self_kindness",
  ]);
  const result: TopicKey[] = [];
  for (const row of rows) {
    const topic = row.topico as TopicKey;
    if (allowed.has(topic) && !result.includes(topic)) result.push(topic);
  }
  return result;
}

function interactionSummaryFor(
  events: EventRow[],
  suggestions: Map<string, SuggestionRow>,
  sources: SupportSource[],
): InteractionSummary {
  const canUseNotifications = sources.includes("notification_interactions");
  const canUseExerciseFeedback = sources.includes("exercise_feedback");
  const notificationEvents = canUseNotifications
    ? events.filter((event) =>
      event.canal === "local_notification" || event.canal === "push"
    )
    : [];
  const opened = canUseNotifications
    ? notificationEvents.filter((event) => event.tipo === "aberta").length
    : 0;
  const preferenceEvents = canUseNotifications
    ? events.filter((event) =>
      [
        "aberta",
        "dispensada",
        "combina_percepcao",
        "nao_combina",
        "util",
        "neutra",
        "nao_ajudou",
        "prejudicial",
      ].includes(event.tipo)
    )
    : [];
  const dismissed = canUseNotifications
    ? preferenceEvents.filter((event) => event.tipo === "dispensada").length
    : 0;
  let consecutiveDismissals = 0;
  if (canUseNotifications) {
    for (const event of preferenceEvents) {
      if (event.tipo === "dispensada") {
        consecutiveDismissals += 1;
      } else {
        break;
      }
    }
  }

  const latestFeedbackByTemplate = new Map<string, string>();
  const feedbackTypes = new Set([
    "combina_percepcao",
    "nao_combina",
    "util",
    "neutra",
    "nao_ajudou",
    "prejudicial",
  ]);
  for (const event of preferenceEvents) {
    if (!feedbackTypes.has(event.tipo) || event.sugestao_id === null) continue;
    const templateId = suggestions.get(event.sugestao_id)?.template_id;
    if (templateId !== null && templateId !== undefined &&
      !latestFeedbackByTemplate.has(templateId)) {
      latestFeedbackByTemplate.set(templateId, event.tipo);
    }
  }
  const negativeTemplateIds = [...latestFeedbackByTemplate.entries()]
    .filter(([, type]) =>
      type === "nao_combina" || type === "nao_ajudou" || type === "prejudicial"
    )
    .map(([templateId]) => templateId);
  const negativeEvents = preferenceEvents.filter((event) =>
    event.tipo === "nao_combina" ||
    event.tipo === "nao_ajudou" ||
    event.tipo === "prejudicial"
  );
  const exerciseNegativeTemplateIds = canUseExerciseFeedback
    ? negativeEvents
        .map((event) =>
          event.sugestao_id === null
            ? null
            : suggestions.get(event.sugestao_id)?.template_id ?? null
        )
        .filter((value): value is string => value !== null)
    : [];
  negativeTemplateIds.push(...exerciseNegativeTemplateIds);
  const previousExerciseWasNotHelpful = canUseExerciseFeedback &&
    negativeEvents.some((event) => {
      if (event.sugestao_id === null) return false;
      const exerciseId = suggestions.get(event.sugestao_id)?.exercicio_id;
      return typeof exerciseId === "string" && exerciseId !== "";
    });
  const blockedTemplates = new Set(negativeTemplateIds);
  const openedSuggestions = notificationEvents
    .filter((event) => event.tipo === "aberta" && event.sugestao_id !== null)
    .map((event) => suggestions.get(event.sugestao_id!))
    .filter((suggestion): suggestion is SuggestionRow =>
      suggestion !== undefined &&
      suggestion.template_id !== null &&
      !blockedTemplates.has(suggestion.template_id)
    );
  const preferredTemplateIds = uniqueStrings(
    openedSuggestions.map((suggestion) => suggestion.template_id!),
  ).slice(0, 3);
  const preferredCategories = uniqueStrings(
    openedSuggestions.map((suggestion) => suggestion.categoria ?? ""),
  )
    .filter((value): value is SupportCategory =>
      (supportCategories as readonly string[]).includes(value)
    )
    .slice(0, 2);

  return {
    opened30Days: opened,
    dismissed30Days: dismissed,
    consecutiveDismissals,
    recentNegativeTemplateIds: [...new Set(negativeTemplateIds)],
    previousExerciseWasNotHelpful,
    preferredTemplateIds,
    preferredCategories,
  };
}

async function requestModelSelection(input: {
  context: SelectionContext;
  patientId: string;
  model: string;
  promptVersion: string;
  safetySalt: string;
}): Promise<ModelAttempt> {
  const startedAt = Date.now();
  const apiKey = Deno.env.get("OPENAI_API_KEY")?.trim() ?? "";
  if (apiKey === "") {
    return modelFailure("openai_secret_missing", startedAt);
  }

  const safetyIdentifier = await hmacHex(
    input.safetySalt,
    input.patientId,
  );
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    modelTimeoutMilliseconds(),
  );
  let response: Response;
  try {
    response = await fetch(openAiResponsesUrl, {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: input.model,
        store: false,
        instructions: selectionInstructions,
        input: JSON.stringify({
          selectionContext: input.context,
          eligibleOptions: eligibleTemplates(input.context).map((template) => ({
            suggestionTemplateId: template.id,
            category: template.category,
            exerciseId: template.exerciseId ?? "NONE",
            allowedReasonCodes: template.allowedReasonCodes,
          })),
        }),
        max_output_tokens: 180,
        safety_identifier: safetyIdentifier,
        metadata: {
          feature: "iris_ai_support_selection",
          prompt_version: input.promptVersion,
        },
        text: {
          format: {
            type: "json_schema",
            name: "iris_support_selection",
            strict: true,
            schema: buildSelectionSchema(input.context),
          },
        },
      }),
    });
  } catch {
    return modelFailure("openai_timeout_or_network", startedAt);
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) {
    const category = response.status === 429
      ? "rate_limited"
      : response.status >= 500
      ? "server_error"
      : "request_rejected";
    return modelFailure(`openai_${category}`, startedAt);
  }

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    return modelFailure("openai_invalid_json", startedAt);
  }
  if (!isRecord(payload) || payload.status !== "completed") {
    return modelFailure("openai_incomplete", startedAt);
  }
  const output = extractStructuredOutput(payload);
  if (output === null) return modelFailure("openai_refusal", startedAt);
  const outputHash = await sha256Hex(output);
  let proposal: unknown;
  try {
    proposal = JSON.parse(output);
  } catch {
    return {
      ...modelFailure("structured_output_invalid_json", startedAt),
      outputHash,
    };
  }
  const validation = validateSelection(proposal, input.context);
  const usage = isRecord(payload.usage) ? payload.usage : null;
  const inputTokens = integerOrNull(usage?.input_tokens);
  const outputTokens = integerOrNull(usage?.output_tokens);
  if (!validation.accepted) {
    return {
      selection: null,
      result: validation.code === "model_abstained" ? "silencio" : "rejeitada",
      validationCode: validation.code,
      outputHash,
      latencyMs: Date.now() - startedAt,
      inputTokens,
      outputTokens,
    };
  }
  return {
    selection: validation.selection,
    result: "sugerida",
    validationCode: "accepted",
    outputHash,
    latencyMs: Date.now() - startedAt,
    inputTokens,
    outputTokens,
  };
}

async function persistRun(
  admin: SupabaseClient,
  input: PersistRunInput,
): Promise<Record<string, unknown>> {
  const now = new Date();
  const selection = input.selection;
  const { data, error } = await admin
    .from("sugestoes_ia_apoio")
    .upsert(
      {
        paciente_id: input.patientId,
        request_id: input.requestId,
        gatilho: input.trigger,
        papel: input.role,
        modo: input.mode,
        origem: input.origin,
        resultado: input.result,
        template_id: selection?.templateId ?? null,
        categoria: selection?.category ?? null,
        exercicio_id: selection?.exerciseId ?? null,
        reason_codes: selection?.reasonCodes ?? [],
        fontes_usadas: selection?.usedSources ?? [],
        confidence_band: selection?.confidenceBand ?? null,
        modelo: input.model,
        versao_prompt: input.promptVersion,
        versao_catalogo: input.catalogVersion,
        validacao_codigo: input.validationCode,
        saida_hash: input.outputHash ?? null,
        latencia_ms: input.latencyMs ?? null,
        tokens_entrada: input.inputTokens ?? null,
        tokens_saida: input.outputTokens ?? null,
        visivel_em:
          input.role === "efetiva" && selection !== null
            ? now.toISOString()
            : null,
        expira_em: new Date(
          now.getTime() + 24 * 60 * 60 * 1000,
        ).toISOString(),
      },
      { onConflict: "paciente_id,request_id,papel" },
    )
    .select(
      "id,request_id,modo,origem,resultado,template_id,categoria," +
        "exercicio_id,reason_codes,fontes_usadas,confidence_band,expira_em",
    )
    .single();
  if (error !== null || data === null) throw new Error("persist_run_failed");
  return data as Record<string, unknown>;
}

async function findEffectiveRun(
  admin: SupabaseClient,
  patientId: string,
  requestId: string,
): Promise<Record<string, unknown> | null> {
  const { data, error } = await admin
    .from("sugestoes_ia_apoio")
    .select(
      "id,request_id,modo,origem,resultado,template_id,categoria," +
        "exercicio_id,reason_codes,fontes_usadas,confidence_band,expira_em",
    )
    .eq("paciente_id", patientId)
    .eq("request_id", requestId)
    .eq("papel", "efetiva")
    .maybeSingle();
  if (error !== null) throw new Error("idempotency_query_failed");
  return data as Record<string, unknown> | null;
}

async function recordServerEvent(
  admin: SupabaseClient,
  input: {
    patientId: string;
    suggestionId: string | null;
    clientEventId: string;
    type: "solicitada" | "gerada";
  },
): Promise<void> {
  const { error } = await admin.from("eventos_ia_apoio").upsert(
    {
      paciente_id: input.patientId,
      sugestao_id: input.suggestionId,
      client_event_id: input.clientEventId,
      tipo: input.type,
      canal: "app",
      ocorrido_em: new Date().toISOString(),
    },
    { onConflict: "paciente_id,client_event_id", ignoreDuplicates: true },
  );
  if (error !== null) throw new Error("persist_event_failed");
}

async function findPatientId(
  admin: SupabaseClient,
  userId: string,
): Promise<string | null> {
  const { data, error } = await admin
    .from("pacientes")
    .select("id")
    .eq("user_id", userId)
    .maybeSingle();
  if (error !== null) throw new Error("patient_query_failed");
  return typeof data?.id === "string" ? data.id : null;
}

async function loadPreferences(
  admin: SupabaseClient,
  patientId: string,
): Promise<PreferencesRow | null> {
  const { data, error } = await admin
    .from("preferencias_ia_apoio")
    .select(
      "personalizacao_ativa,fontes_consentidas,categorias_permitidas," +
        "duracao_maxima_minutos,conteudos_excluidos,fuso_horario,pausado_ate",
    )
    .eq("paciente_id", patientId)
    .maybeSingle();
  if (error !== null) throw new Error("preferences_query_failed");
  return data as PreferencesRow | null;
}

async function loadRollout(
  admin: SupabaseClient,
  environment: string,
): Promise<RolloutConfiguration> {
  const { data, error } = await admin
    .from("rollout_ia_apoio")
    .select(
      "ambiente,apoio_ativo,modo,openai_ativa,kill_switch," +
        "percentual_shadow,percentual_entrega,modelo,versao_prompt," +
        "versao_catalogo",
    )
    .eq("ambiente", environment)
    .maybeSingle();
  if (error !== null) throw new Error("rollout_query_failed");
  if (data === null) {
    return {
      ambiente: environment,
      apoio_ativo: true,
      modo: "local",
      openai_ativa: false,
      kill_switch: true,
      percentual_shadow: 0,
      percentual_entrega: 0,
      modelo: null,
      versao_prompt: "selection-v1",
      versao_catalogo: "support-v1",
    };
  }
  return data as RolloutConfiguration;
}

async function isActivePilotParticipant(
  admin: SupabaseClient,
  patientId: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from("participantes_piloto_ia_apoio")
    .select("paciente_id")
    .eq("paciente_id", patientId)
    .eq("ativo", true)
    .maybeSingle();
  if (error !== null) throw new Error("pilot_query_failed");
  return data !== null;
}

function parseRequestBody(value: unknown): RequestBody {
  if (!isRecord(value) || Object.keys(value).length !== 2) {
    throw new Error("invalid_request");
  }
  if (
    typeof value.requestId !== "string" ||
    !uuidPattern.test(value.requestId) ||
    typeof value.trigger !== "string" ||
    !allowedTriggers.has(value.trigger)
  ) {
    throw new Error("invalid_request");
  }
  return { requestId: value.requestId, trigger: value.trigger };
}

function responseForRun(row: Record<string, unknown>) {
  const base = {
    requestId: row.request_id,
    mode: row.modo,
  };
  if (row.resultado !== "sugerida") {
    return { ...base, status: "silent", proposal: null };
  }
  return {
    ...base,
    status: "suggested",
    suggestionId: row.id,
    templateId: row.template_id,
    category: row.categoria,
    exerciseId: row.exercicio_id,
    reasonCodes: row.reason_codes,
    confidenceBand: row.confidence_band,
    usedSources: row.fontes_usadas,
    origin: row.origem,
    proposal: {
      suggestionTemplateId: row.template_id,
      exerciseId: row.exercicio_id,
      reasonCodes: row.reason_codes,
      confidenceBand: row.confidence_band,
    },
    expiresAt: row.expira_em,
  };
}

function readSupabaseKey(jsonName: string, legacyName: string): string {
  const jsonValue = Deno.env.get(jsonName)?.trim();
  if (jsonValue !== undefined && jsonValue !== "") {
    try {
      const keys = JSON.parse(jsonValue) as Record<string, unknown>;
      if (typeof keys.default === "string") return keys.default;
    } catch {
      return "";
    }
  }
  return Deno.env.get(legacyName)?.trim() ?? "";
}

function normalizedEnvironment(value: string | undefined): string {
  return value === "development" || value === "staging" || value === "production"
    ? value
    : "production";
}

function isPaused(value: string | null): boolean {
  if (value === null) return false;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) && parsed > Date.now();
}

function average(values: number[]): number {
  return values.reduce((total, value) => total + value, 0) / values.length;
}

function localIsoDate(now: Date, timeZone: string): string {
  const offset = timeZone.match(/UTC([+-])(\d{2}):(\d{2})/i);
  if (offset !== null) {
    const hours = Number(offset[2]);
    const remainderMinutes = Number(offset[3]);
    if (hours <= 23 && remainderMinutes <= 59) {
      const minutes = hours * 60 + remainderMinutes;
      const signedMinutes = offset[1] === "-" ? -minutes : minutes;
      return new Date(now.getTime() + signedMinutes * 60 * 1000)
        .toISOString()
        .slice(0, 10);
    }
  }
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).formatToParts(now);
    const value = Object.fromEntries(
      parts.map((part) => [part.type, part.value]),
    );
    if (value.year && value.month && value.day) {
      return `${value.year}-${value.month}-${value.day}`;
    }
  } catch {
    // Um fuso legado invalido nao pode interromper o check-in principal.
  }
  return now.toISOString().slice(0, 10);
}

function uniqueStrings(values: string[]): string[] {
  return [...new Set(values.filter((value) => value !== ""))];
}

function modelFailure(code: string, startedAt: number): ModelAttempt {
  return {
    selection: null,
    result: "erro",
    validationCode: code,
    outputHash: null,
    latencyMs: Date.now() - startedAt,
    inputTokens: null,
    outputTokens: null,
  };
}

function modelTimeoutMilliseconds(): number {
  const parsed = Number.parseInt(Deno.env.get("OPENAI_TIMEOUT_MS") ?? "6000", 10);
  if (!Number.isFinite(parsed)) return 6000;
  return Math.min(10000, Math.max(1000, parsed));
}

async function stableBucket(
  patientId: string,
  salt: string,
  purpose: string,
): Promise<number> {
  const digest = await hmacHex(salt, `${purpose}:${patientId}`);
  return Number.parseInt(digest.slice(0, 8), 16) % 100;
}

async function hmacHex(secret: string, value: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(value),
  );
  return bytesToHex(new Uint8Array(signature));
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return bytesToHex(new Uint8Array(digest));
}

function bytesToHex(bytes: Uint8Array): string {
  return [...bytes]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

function integerOrNull(value: unknown): number | null {
  return Number.isInteger(value) && (value as number) >= 0
    ? (value as number)
    : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function corsHeadersFor(origin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Cache-Control": "no-store",
    Vary: "Origin",
  };
  if (origin === null) return headers;
  const allowed = new Set(
    (Deno.env.get("AI_SUPPORT_ALLOWED_ORIGINS") ?? "")
      .split(",")
      .map((value) => value.trim())
      .filter((value) => value !== ""),
  );
  if (allowed.has(origin)) headers["Access-Control-Allow-Origin"] = origin;
  return headers;
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...extraHeaders,
    },
  });
}

function auditLog(code: string, requestId: string): void {
  // Nao registrar payload, resposta do modelo, identificador do paciente ou
  // valores de secrets. Estes dois campos sao operacionais e nao clinicos.
  console.error(JSON.stringify({ code, requestId }));
}
