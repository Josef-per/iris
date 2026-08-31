export const supportSources = [
  "mood_history",
  "diary_topics",
  "exercise_feedback",
  "notification_interactions",
] as const;

export const supportCategories = [
  "reflection",
  "exercise",
  "video",
  "human_connection",
  "professional_conversation",
] as const;

export const supportReasonCodes = [
  "TODAY_DIFFICULT_CHECKIN",
  "TODAY_STEADY_CHECKIN",
  "TODAY_LIGHTER_CHECKIN",
  "RECENT_DIFFICULT_CHECKINS",
  "PREFERS_SHORT_PRACTICE",
  "CONFIRMED_OVERLOAD",
  "CONFIRMED_LONELINESS",
  "CONFIRMED_SELF_KINDNESS",
  "PREFERRED_FROM_PAST_INTERACTIONS",
  "PREVIOUS_EXERCISE_WAS_NOT_HELPFUL",
] as const;

export type SupportSource = (typeof supportSources)[number];
export type SupportCategory = (typeof supportCategories)[number];
export type SupportReasonCode = (typeof supportReasonCodes)[number];
export type ConfidenceBand = "low" | "medium" | "high";
export type TopicKey = "overload" | "loneliness" | "self_kindness";
export type SupportTrigger =
  | "manual"
  | "after_checkin"
  | "after_diary"
  | "notification_open";

type TemplateDefinition = {
  id: string;
  category: SupportCategory;
  exerciseId: string | null;
  durationMinutes: number | null;
  contentTags: readonly string[];
  allowedReasonCodes: readonly SupportReasonCode[];
};

// O modelo escolhe somente IDs deste catalogo fechado. O texto mostrado ao
// paciente continua vindo do catalogo revisado do aplicativo/backend.
export const supportTemplates: readonly TemplateDefinition[] = [
  {
    id: "reflection_difficult_checkins_v1",
    category: "reflection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "TODAY_DIFFICULT_CHECKIN",
      "RECENT_DIFFICULT_CHECKINS",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "exercise_difficult_checkins_v1",
    category: "exercise",
    exerciseId: "anchor-present",
    durationMinutes: 2,
    contentTags: [],
    allowedReasonCodes: [
      "RECENT_DIFFICULT_CHECKINS",
      "PREFERS_SHORT_PRACTICE",
      "TODAY_DIFFICULT_CHECKIN",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "reflection_overload_v1",
    category: "reflection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "CONFIRMED_OVERLOAD",
      "TODAY_STEADY_CHECKIN",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "connection_loneliness_v1",
    category: "human_connection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "CONFIRMED_LONELINESS",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "reflection_lighter_checkin_v1",
    category: "reflection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "TODAY_LIGHTER_CHECKIN",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "reflection_self_kindness_v1",
    category: "reflection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "CONFIRMED_SELF_KINDNESS",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
  {
    id: "connection_after_exercise_feedback_v1",
    category: "human_connection",
    exerciseId: null,
    durationMinutes: null,
    contentTags: [],
    allowedReasonCodes: [
      "PREVIOUS_EXERCISE_WAS_NOT_HELPFUL",
      "PREFERRED_FROM_PAST_INTERACTIONS",
    ],
  },
] as const;

export type SelectionProposal = {
  decision: "suggest" | "abstain";
  suggestionTemplateId: string;
  exerciseId: string;
  reasonCodes: string[];
  confidenceBand: ConfidenceBand;
};

export type AcceptedSelection = {
  templateId: string;
  category: SupportCategory;
  exerciseId: string | null;
  reasonCodes: SupportReasonCode[];
  usedSources: SupportSource[];
  confidenceBand: "medium" | "high";
};

export type MoodTrend = {
  direction: "difficult" | "stable" | "easier";
  difficultCheckInCount: number;
  sampleSize: number;
  windowDays: number;
};

export type DailyCheckIn = {
  moodBand: "difficult" | "steady" | "lighter";
};

export type InteractionSummary = {
  opened30Days: number;
  dismissed30Days: number;
  consecutiveDismissals: number;
  recentNegativeTemplateIds: string[];
  previousExerciseWasNotHelpful: boolean;
  preferredTemplateIds: string[];
  preferredCategories: SupportCategory[];
};

export type SelectionContext = {
  schemaVersion: "1";
  trigger: SupportTrigger;
  allowedCategories: SupportCategory[];
  maximumExerciseMinutes: number;
  excludedContentTags: string[];
  consentedSources: SupportSource[];
  dailyCheckIn: DailyCheckIn | null;
  moodTrend: MoodTrend | null;
  confirmedTopics: TopicKey[];
  interactions: InteractionSummary;
  recentTemplateIds: string[];
};

export type ValidationResult =
  | { accepted: true; selection: AcceptedSelection }
  | { accepted: false; code: string };

export function eligibleTemplates(
  context: SelectionContext,
): readonly TemplateDefinition[] {
  return supportTemplates.filter((template) => {
    if (!context.allowedCategories.includes(template.category)) return false;
    if (context.recentTemplateIds.includes(template.id)) return false;
    if (context.interactions.recentNegativeTemplateIds.includes(template.id)) {
      return false;
    }
    if (
      template.durationMinutes !== null &&
      template.durationMinutes > context.maximumExerciseMinutes
    ) {
      return false;
    }
    return !template.contentTags.some((tag) =>
      context.excludedContentTags.includes(tag)
    );
  });
}

export function buildSelectionSchema(context: SelectionContext) {
  const templates = eligibleTemplates(context);
  const templateIds = ["NONE", ...templates.map((item) => item.id)];
  const exerciseIds = [
    "NONE",
    ...new Set(
      templates
        .map((item) => item.exerciseId)
        .filter((value): value is string => value !== null),
    ),
  ];

  return {
    type: "object",
    additionalProperties: false,
    properties: {
      decision: { type: "string", enum: ["suggest", "abstain"] },
      suggestionTemplateId: { type: "string", enum: templateIds },
      exerciseId: { type: "string", enum: exerciseIds },
      reasonCodes: {
        type: "array",
        items: { type: "string", enum: supportReasonCodes },
        maxItems: 4,
      },
      confidenceBand: {
        type: "string",
        enum: ["low", "medium", "high"],
      },
    },
    required: [
      "decision",
      "suggestionTemplateId",
      "exerciseId",
      "reasonCodes",
      "confidenceBand",
    ],
  } as const;
}

export function validateSelection(
  value: unknown,
  context: SelectionContext,
): ValidationResult {
  if (!isRecord(value)) return rejected("invalid_schema");
  const exactKeys = [
    "decision",
    "suggestionTemplateId",
    "exerciseId",
    "reasonCodes",
    "confidenceBand",
  ];
  if (
    Object.keys(value).length !== exactKeys.length ||
    !exactKeys.every((key) => Object.hasOwn(value, key))
  ) {
    return rejected("invalid_schema");
  }

  const decision = value.decision;
  const templateId = value.suggestionTemplateId;
  const exerciseId = value.exerciseId;
  const rawReasons = value.reasonCodes;
  const confidence = value.confidenceBand;
  if (
    (decision !== "suggest" && decision !== "abstain") ||
    typeof templateId !== "string" ||
    typeof exerciseId !== "string" ||
    !Array.isArray(rawReasons) ||
    !rawReasons.every((reason) => typeof reason === "string") ||
    (confidence !== "low" && confidence !== "medium" && confidence !== "high")
  ) {
    return rejected("invalid_schema");
  }

  if (decision === "abstain") {
    if (
      templateId !== "NONE" ||
      exerciseId !== "NONE" ||
      rawReasons.length !== 0
    ) {
      return rejected("invalid_abstention");
    }
    return rejected("model_abstained");
  }
  if (confidence === "low") return rejected("confidence_too_low");
  if (templateId === "NONE" || rawReasons.length === 0) {
    return rejected("missing_selection");
  }
  if (new Set(rawReasons).size !== rawReasons.length) {
    return rejected("duplicate_reason_code");
  }
  if (
    !rawReasons.every((reason) =>
      (supportReasonCodes as readonly string[]).includes(reason)
    )
  ) {
    return rejected("unknown_reason_code");
  }

  const template = eligibleTemplates(context).find(
    (candidate) => candidate.id === templateId,
  );
  if (template === undefined) return rejected("template_not_allowed");
  const expectedExerciseId = template.exerciseId ?? "NONE";
  if (exerciseId !== expectedExerciseId) {
    return rejected("exercise_does_not_match_template");
  }
  if (
    !rawReasons.every((reason) =>
      (template.allowedReasonCodes as readonly string[]).includes(reason)
    )
  ) {
    return rejected("reason_not_allowed_for_template");
  }

  const reasons = rawReasons as SupportReasonCode[];
  const modifierReasons = new Set<SupportReasonCode>([
    "PREFERS_SHORT_PRACTICE",
    "PREFERRED_FROM_PAST_INTERACTIONS",
  ]);
  if (reasons.every((reason) => modifierReasons.has(reason))) {
    return rejected("preference_without_current_evidence");
  }
  for (const reason of reasons) {
    if (!hasEvidence(reason, context, template)) {
      return rejected("reason_without_consented_evidence");
    }
  }

  const usedSources = [
    ...new Set(reasons.map(sourceForReason).filter(isSupportSource)),
  ] as SupportSource[];
  if (!usedSources.every((source) => context.consentedSources.includes(source))) {
    return rejected("source_not_consented");
  }

  return {
    accepted: true,
    selection: {
      templateId: template.id,
      category: template.category,
      exerciseId: template.exerciseId,
      reasonCodes: reasons,
      usedSources,
      confidenceBand: confidence,
    },
  };
}

export function localSelection(
  context: SelectionContext,
): AcceptedSelection | null {
  const proposals: SelectionProposal[] = [];
  if (context.interactions.previousExerciseWasNotHelpful) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "connection_after_exercise_feedback_v1",
      exerciseId: "NONE",
      reasonCodes: ["PREVIOUS_EXERCISE_WAS_NOT_HELPFUL"],
      confidenceBand: "high",
    });
  }
  if (context.confirmedTopics.includes("loneliness")) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "connection_loneliness_v1",
      exerciseId: "NONE",
      reasonCodes: ["CONFIRMED_LONELINESS"],
      confidenceBand: "high",
    });
  }
  const difficultToday = context.dailyCheckIn?.moodBand === "difficult";
  const difficultTrend = context.moodTrend?.direction === "difficult";
  if (
    (difficultToday || difficultTrend) &&
    !context.interactions.previousExerciseWasNotHelpful
  ) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "exercise_difficult_checkins_v1",
      exerciseId: "anchor-present",
      reasonCodes: [
        ...(difficultToday ? ["TODAY_DIFFICULT_CHECKIN" as const] : []),
        ...(difficultTrend ? ["RECENT_DIFFICULT_CHECKINS" as const] : []),
        "PREFERS_SHORT_PRACTICE",
      ],
      confidenceBand: "medium",
    });
  }
  if (difficultToday || difficultTrend) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "reflection_difficult_checkins_v1",
      exerciseId: "NONE",
      reasonCodes: [
        ...(difficultToday ? ["TODAY_DIFFICULT_CHECKIN" as const] : []),
        ...(difficultTrend ? ["RECENT_DIFFICULT_CHECKINS" as const] : []),
      ],
      confidenceBand: "medium",
    });
  }
  if (context.confirmedTopics.includes("overload")) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "reflection_overload_v1",
      exerciseId: "NONE",
      reasonCodes: ["CONFIRMED_OVERLOAD"],
      confidenceBand: "high",
    });
  }
  if (context.dailyCheckIn?.moodBand === "steady") {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "reflection_overload_v1",
      exerciseId: "NONE",
      reasonCodes: ["TODAY_STEADY_CHECKIN"],
      confidenceBand: "high",
    });
  }
  if (context.dailyCheckIn?.moodBand === "lighter") {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "reflection_lighter_checkin_v1",
      exerciseId: "NONE",
      reasonCodes: ["TODAY_LIGHTER_CHECKIN"],
      confidenceBand: "high",
    });
  }
  if (context.confirmedTopics.includes("self_kindness")) {
    proposals.push({
      decision: "suggest",
      suggestionTemplateId: "reflection_self_kindness_v1",
      exerciseId: "NONE",
      reasonCodes: ["CONFIRMED_SELF_KINDNESS"],
      confidenceBand: "high",
    });
  }

  const personalized = prioritizeFromInteractions(proposals, context);
  for (const proposal of prioritizeForTrigger(personalized, context)) {
    const result = validateSelection(proposal, context);
    if (result.accepted) return result.selection;
  }
  return null;
}

export function extractStructuredOutput(response: unknown): string | null {
  if (!isRecord(response) || !Array.isArray(response.output)) return null;
  for (const item of response.output) {
    if (!isRecord(item) || !Array.isArray(item.content)) continue;
    for (const content of item.content) {
      if (!isRecord(content)) continue;
      if (content.type === "refusal") return null;
      if (content.type === "output_text" && typeof content.text === "string") {
        return content.text;
      }
    }
  }
  return null;
}

function hasEvidence(
  reason: SupportReasonCode,
  context: SelectionContext,
  template: TemplateDefinition,
): boolean {
  switch (reason) {
    case "TODAY_DIFFICULT_CHECKIN":
      return (
        context.consentedSources.includes("mood_history") &&
        context.dailyCheckIn?.moodBand === "difficult"
      );
    case "TODAY_STEADY_CHECKIN":
      return (
        context.consentedSources.includes("mood_history") &&
        context.dailyCheckIn?.moodBand === "steady"
      );
    case "TODAY_LIGHTER_CHECKIN":
      return (
        context.consentedSources.includes("mood_history") &&
        context.dailyCheckIn?.moodBand === "lighter"
      );
    case "RECENT_DIFFICULT_CHECKINS":
      return (
        context.consentedSources.includes("mood_history") &&
        context.moodTrend?.direction === "difficult" &&
        context.moodTrend.difficultCheckInCount >= 3 &&
        context.moodTrend.sampleSize >= 4
      );
    case "PREFERS_SHORT_PRACTICE":
      return context.maximumExerciseMinutes <= 2;
    case "CONFIRMED_OVERLOAD":
      return (
        context.consentedSources.includes("diary_topics") &&
        context.confirmedTopics.includes("overload")
      );
    case "CONFIRMED_LONELINESS":
      return (
        context.consentedSources.includes("diary_topics") &&
        context.confirmedTopics.includes("loneliness")
      );
    case "CONFIRMED_SELF_KINDNESS":
      return (
        context.consentedSources.includes("diary_topics") &&
        context.confirmedTopics.includes("self_kindness")
      );
    case "PREFERRED_FROM_PAST_INTERACTIONS":
      return (
        context.consentedSources.includes("notification_interactions") &&
        (context.interactions.preferredTemplateIds.includes(template.id) ||
          context.interactions.preferredCategories.includes(template.category))
      );
    case "PREVIOUS_EXERCISE_WAS_NOT_HELPFUL":
      return (
        context.consentedSources.includes("exercise_feedback") &&
        context.interactions.previousExerciseWasNotHelpful
      );
  }
}

function sourceForReason(reason: SupportReasonCode): SupportSource | null {
  switch (reason) {
    case "TODAY_DIFFICULT_CHECKIN":
    case "TODAY_STEADY_CHECKIN":
    case "TODAY_LIGHTER_CHECKIN":
    case "RECENT_DIFFICULT_CHECKINS":
      return "mood_history";
    case "PREFERS_SHORT_PRACTICE":
      return null;
    case "CONFIRMED_OVERLOAD":
    case "CONFIRMED_LONELINESS":
    case "CONFIRMED_SELF_KINDNESS":
      return "diary_topics";
    case "PREFERRED_FROM_PAST_INTERACTIONS":
      return "notification_interactions";
    case "PREVIOUS_EXERCISE_WAS_NOT_HELPFUL":
      return "exercise_feedback";
  }
}

function prioritizeFromInteractions(
  proposals: SelectionProposal[],
  context: SelectionContext,
): SelectionProposal[] {
  const ranked = proposals.map((proposal, originalIndex) => {
    const template = supportTemplates.find(
      (candidate) => candidate.id === proposal.suggestionTemplateId,
    );
    const preferenceRank = template === undefined ||
        !context.consentedSources.includes("notification_interactions")
      ? 2
      : context.interactions.preferredTemplateIds.includes(template.id)
      ? 0
      : context.interactions.preferredCategories.includes(template.category)
      ? 1
      : 2;
    const enriched: SelectionProposal = preferenceRank < 2
      ? {
        ...proposal,
        reasonCodes: [
          ...proposal.reasonCodes,
          "PREFERRED_FROM_PAST_INTERACTIONS",
        ],
      }
      : proposal;
    return {
      originalIndex,
      preferenceRank,
      proposal: enriched,
    };
  });
  ranked.sort((left, right) => {
    if (left.preferenceRank === right.preferenceRank) {
      return left.originalIndex - right.originalIndex;
    }
    return left.preferenceRank - right.preferenceRank;
  });
  return ranked.map((item) => item.proposal);
}

function prioritizeForTrigger(
  proposals: SelectionProposal[],
  context: SelectionContext,
): SelectionProposal[] {
  if (context.trigger === "notification_open") return proposals;
  const ranked = proposals.map((proposal, originalIndex) => ({
    proposal,
    originalIndex,
    rank: triggerRank(proposal, context),
  }));
  ranked.sort((left, right) =>
    left.rank === right.rank
      ? left.originalIndex - right.originalIndex
      : left.rank - right.rank
  );
  return ranked.map((item) => item.proposal);
}

function triggerRank(
  proposal: SelectionProposal,
  context: SelectionContext,
): number {
  const hasDiaryEvidence = proposal.reasonCodes.some((reason) =>
    reason === "CONFIRMED_OVERLOAD" ||
    reason === "CONFIRMED_LONELINESS" ||
    reason === "CONFIRMED_SELF_KINDNESS"
  );
  const hasCheckInEvidence = proposal.reasonCodes.some((reason) =>
    reason === "TODAY_DIFFICULT_CHECKIN" ||
    reason === "TODAY_STEADY_CHECKIN" ||
    reason === "TODAY_LIGHTER_CHECKIN" ||
    reason === "RECENT_DIFFICULT_CHECKINS"
  );
  const todayEvidence = proposal.reasonCodes.some((reason) =>
    reason === "TODAY_DIFFICULT_CHECKIN" ||
    reason === "TODAY_STEADY_CHECKIN" ||
    reason === "TODAY_LIGHTER_CHECKIN"
  );
  const topic = proposal.reasonCodes.includes("CONFIRMED_OVERLOAD")
    ? "overload"
    : proposal.reasonCodes.includes("CONFIRMED_LONELINESS")
    ? "loneliness"
    : proposal.reasonCodes.includes("CONFIRMED_SELF_KINDNESS")
    ? "self_kindness"
    : null;
  const topicRecency = topic === null
    ? 9
    : Math.max(0, context.confirmedTopics.indexOf(topic));
  if (context.trigger === "after_diary") {
    return hasDiaryEvidence
      ? topicRecency
      : hasCheckInEvidence
      ? 20 + (todayEvidence ? 0 : 1)
      : 40;
  }
  return hasCheckInEvidence
    ? (todayEvidence ? 0 : 1)
    : hasDiaryEvidence
    ? 20 + topicRecency
    : 40;
}

function isSupportSource(value: SupportSource | null): value is SupportSource {
  return value !== null;
}

function rejected(code: string): ValidationResult {
  return { accepted: false, code };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
