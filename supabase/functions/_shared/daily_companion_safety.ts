const unsafeClinicalOrFood =
  /\b(diagnost|transtorno|doen[cç]a|medica[cã]o|caloria|emagre[cç]|peso ideal)\b/i;

const exerciseLike =
  /\b(respira|medita|exerc[ií]cio|atividade f[ií]sica|along|aterramento|escaneamento corporal|pr[aá]tica guiada|conte at[eé]|reserve (um|dois|tr[eê]s|alguns) minutos?)\b/i;

// Uma reflexao pode reconhecer uma tensao relacional, mas nao deve transformar
// poucas linhas de diario em uma decisao sobre vinculos ou rede de apoio.
const consequentialRelationshipDirective = new RegExp(
  [
    String.raw`\b(?:reduz(?:ir|a)|cort(?:ar|e))\s+(?:o\s+)?contatos?\b`,
    String.raw`\b(?:afast(?:ar|e|amento)(?:-se)?)\b`,
    String.raw`\bevit(?:ar|e)\s+(?:contatos?|conversas?|pessoas?|interven[cç][oõ]es?)\b`,
    String.raw`\b(?:romp(?:er|a)|termin(?:ar|e))\s+(?:a\s+)?rela[cç][aã]o\b`,
    String.raw`\b(?:s[oó]|somente)\s+retom(?:ar|e)\b`,
    String.raw`\b(?:n[aã]o|pare\s+de)\s+fal(?:e|ar)\s+com\b`,
    String.raw`\b(?:diz(?:er|a)|inform(?:ar|e))\s+(?:a|à|ao)\s+(?:fam[ií]lia|amig[oa]s?|parceir[oa])\s+que\b`,
    String.raw`\b(?:criar|estabelecer|impor)\s+(?:um\s+)?limite.{0,40}\b(?:fam[ií]lia|amig[oa]s?|parceir[oa])\b`,
    String.raw`\bper[ií]odo.{0,30}\bsem\s+(?:discuss(?:[aã]o|[oõ]es)|conversas?|contato)\b`,
    String.raw`\b(?:alguns?|poucos?)\s+dias\s+sem\s+(?:falar|conversar|contato)\b`,
    String.raw`\brecus(?:ar|e)\s+(?:ajuda|apoio|interven[cç][aã]o)\b`,
  ].join("|"),
  "i",
);

export function containsProhibitedDailyCompanionContent(
  text: string,
): boolean {
  return unsafeClinicalOrFood.test(text) ||
    exerciseLike.test(text) ||
    consequentialRelationshipDirective.test(text);
}
