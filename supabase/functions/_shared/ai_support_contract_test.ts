import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

import {
  buildSelectionSchema,
  eligibleTemplates,
  type SelectionContext,
  validateSelection,
} from "./ai_support_contract.ts";

const edgeFunctionSource = readFileSync(
  new URL("../ai-support-recommend/index.ts", import.meta.url),
  "utf8",
);

function context(
  overrides: Partial<SelectionContext> = {},
): SelectionContext {
  return {
    schemaVersion: "1",
    trigger: "manual",
    allowedCategories: ["reflection", "exercise", "human_connection"],
    maximumExerciseMinutes: 2,
    excludedContentTags: [],
    consentedSources: [
      "mood_history",
      "diary_topics",
      "exercise_feedback",
      "notification_interactions",
    ],
    dailyCheckIn: null,
    moodTrend: null,
    confirmedTopics: [],
    interactions: {
      opened30Days: 0,
      dismissed30Days: 0,
      consecutiveDismissals: 0,
      recentNegativeTemplateIds: [],
      previousExerciseWasNotHelpful: false,
      preferredTemplateIds: [],
      preferredCategories: [],
    },
    recentTemplateIds: [],
    ...overrides,
  };
}

test("aceita sugestao baseada somente na faixa do check-in de hoje", () => {
  const result = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "reflection_lighter_checkin_v1",
      exerciseId: "NONE",
      reasonCodes: ["TODAY_LIGHTER_CHECKIN"],
      confidenceBand: "high",
    },
    context({ dailyCheckIn: { moodBand: "lighter" } }),
  );

  assert.equal(result.accepted, true);
  if (result.accepted) {
    assert.deepEqual(result.selection.usedSources, ["mood_history"]);
  }
});

test("usa apoio generico para check-in estavel sem inferir sobrecarga", () => {
  const input = context({ dailyCheckIn: { moodBand: "steady" } });

  assert.deepEqual(
    eligibleTemplates(input).map((template) => ({
      id: template.id,
      reasonCodes: template.allowedReasonCodes,
    })),
    [
      {
        id: "reflection_self_kindness_v1",
        reasonCodes: ["TODAY_STEADY_CHECKIN"],
      },
    ],
  );

  const result = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "reflection_self_kindness_v1",
      exerciseId: "NONE",
      reasonCodes: ["TODAY_STEADY_CHECKIN"],
      confidenceBand: "high",
    },
    input,
  );
  assert.equal(result.accepted, true);
});

test("oferece ao modelo somente templates e motivos com evidencia consentida", () => {
  const input = context({ dailyCheckIn: { moodBand: "lighter" } });
  const templates = eligibleTemplates(input);

  assert.deepEqual(
    templates.map((template) => ({
      id: template.id,
      reasonCodes: template.allowedReasonCodes,
    })),
    [
      {
        id: "reflection_lighter_checkin_v1",
        reasonCodes: ["TODAY_LIGHTER_CHECKIN"],
      },
    ],
  );

  const schema = buildSelectionSchema(input);
  assert.deepEqual(schema.properties.reasonCodes.items.enum, [
    "TODAY_LIGHTER_CHECKIN",
  ]);
  assert.deepEqual(schema.properties.suggestionTemplateId.enum, [
    "NONE",
    "reflection_lighter_checkin_v1",
  ]);
});

test("nao oferece template quando existem apenas preferencias modificadoras", () => {
  const input = context({
    interactions: {
      ...context().interactions,
      opened30Days: 1,
      preferredCategories: ["reflection"],
    },
  });

  assert.deepEqual(eligibleTemplates(input), []);
  assert.deepEqual(
    buildSelectionSchema(input).properties.reasonCodes.items.enum,
    [],
  );
});

test("nao transforma dado sem consentimento em motivo elegivel", () => {
  const input = context({
    consentedSources: ["diary_topics"],
    dailyCheckIn: { moodBand: "lighter" },
  });

  assert.deepEqual(eligibleTemplates(input), []);
  assert.deepEqual(
    validateSelection(
      {
        decision: "suggest",
        suggestionTemplateId: "reflection_lighter_checkin_v1",
        exerciseId: "NONE",
        reasonCodes: ["TODAY_LIGHTER_CHECKIN"],
        confidenceBand: "high",
      },
      input,
    ),
    { accepted: false, code: "reason_without_consented_evidence" },
  );
});

test("aceita somente topico fechado e confirmado de autogentileza", () => {
  const result = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "reflection_self_kindness_v1",
      exerciseId: "NONE",
      reasonCodes: ["CONFIRMED_SELF_KINDNESS"],
      confidenceBand: "high",
    },
    context({ confirmedTopics: ["self_kindness"] }),
  );

  assert.equal(result.accepted, true);
});

test("interacao passada apenas personaliza uma evidencia atual", () => {
  const input = context({
    interactions: {
      ...context().interactions,
      opened30Days: 1,
      preferredCategories: ["reflection"],
    },
  });
  const withoutCurrentEvidence = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "reflection_lighter_checkin_v1",
      exerciseId: "NONE",
      reasonCodes: ["PREFERRED_FROM_PAST_INTERACTIONS"],
      confidenceBand: "high",
    },
    input,
  );
  assert.deepEqual(withoutCurrentEvidence, {
    accepted: false,
    code: "preference_without_current_evidence",
  });

  const withCurrentEvidence = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "reflection_lighter_checkin_v1",
      exerciseId: "NONE",
      reasonCodes: [
        "TODAY_LIGHTER_CHECKIN",
        "PREFERRED_FROM_PAST_INTERACTIONS",
      ],
      confidenceBand: "high",
    },
    {
      ...input,
      dailyCheckIn: { moodBand: "lighter" },
    },
  );
  assert.equal(withCurrentEvidence.accepted, true);
  if (withCurrentEvidence.accepted) {
    assert.deepEqual(withCurrentEvidence.selection.usedSources, [
      "mood_history",
      "notification_interactions",
    ]);
  }
});

test("descarta motivo extra sem perder uma selecao sustentada", () => {
  const result = validateSelection(
    {
      decision: "suggest",
      suggestionTemplateId: "exercise_difficult_checkins_v1",
      exerciseId: "anchor-present",
      reasonCodes: [
        "TODAY_DIFFICULT_CHECKIN",
        "PREFERRED_FROM_PAST_INTERACTIONS",
      ],
      confidenceBand: "high",
    },
    context({
      dailyCheckIn: { moodBand: "difficult" },
      interactions: {
        ...context().interactions,
        preferredCategories: ["reflection"],
      },
    }),
  );

  assert.equal(result.accepted, true);
  if (result.accepted) {
    assert.deepEqual(result.selection.reasonCodes, [
      "TODAY_DIFFICULT_CHECKIN",
    ]);
    assert.deepEqual(result.selection.usedSources, ["mood_history"]);
  }
});

test("fronteira OpenAI usa Responses, schema estrito e nao armazena resposta", () => {
  assert.match(edgeFunctionSource, /https:\/\/api\.openai\.com\/v1\/responses/);
  assert.match(edgeFunctionSource, /store:\s*false/);
  assert.match(edgeFunctionSource, /type:\s*"json_schema"/);
  assert.match(edgeFunctionSource, /strict:\s*true/);
  assert.match(edgeFunctionSource, /reasoning:\s*\{\s*effort:\s*"minimal"\s*\}/);
  assert.match(edgeFunctionSource, /safety_identifier:\s*safetyIdentifier/);
  assert.doesNotMatch(edgeFunctionSource, /localSelection/);
});

test("funcao nao consulta texto do diario, alimentacao ou sintomas", () => {
  for (const forbiddenColumn of [
    "diario_emocional",
    "avaliacao_alimentacao",
    "sintomas_emocionais_hoje",
    "sintomas_fisicos_hoje",
    "descricao_refeicao",
    "nivel_fome",
  ]) {
    assert.equal(edgeFunctionSource.includes(forbiddenColumn), false);
  }
  assert.match(
    edgeFunctionSource,
    /\.select\("data_local,fuso_horario,como_sentiu"\)/,
  );
});

test("tendencia de humor consulta somente a janela local de sete dias", () => {
  assert.match(
    edgeFunctionSource,
    /\.gte\("data_local", moodWindowStart\)/,
  );
  assert.match(edgeFunctionSource, /windowDays:\s*7/);
});

test("nao combina participa do bloqueio persistido de template", () => {
  assert.match(edgeFunctionSource, /type === "nao_combina"/);
  assert.match(edgeFunctionSource, /latestFeedbackByTemplate/);
});

test("cliente fornece somente idempotencia e gatilho fechado", () => {
  assert.match(
    edgeFunctionSource,
    /Object\.keys\(value\)\.length !== 2/,
  );
  assert.match(edgeFunctionSource, /requestId:\s*string/);
  assert.match(edgeFunctionSource, /trigger:\s*string/);
  assert.match(edgeFunctionSource, /mode:\s*row\.modo/);
  assert.match(edgeFunctionSource, /proposal:\s*\{/);
});
