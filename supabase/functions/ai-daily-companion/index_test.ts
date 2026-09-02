import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

import { containsProhibitedDailyCompanionContent } from "../_shared/daily_companion_safety.ts";

const source = readFileSync(new URL("./index.ts", import.meta.url), "utf8");

test("reflexao diaria pede orientacao concreta sem exercicios", () => {
  assert.match(source, /orientacao-reflexao personalizada/);
  assert.match(source, /A reflexao nao e um exercicio/);
  assert.match(source, /Retorne reflectionQuestion como null/);
  assert.match(source, /promptVersion = "daily-companion-v2"/);
  assert.match(source, /value\.reflectionQuestion !== null/);
  assert.match(source, /containsProhibitedDailyCompanionContent/);
});

test("bloqueia prescricao de afastamento da familia", () => {
  const unsafe = `
    Criar um limite temporario com a familia. Talvez seja util dizer a familia
    que vai reduzir contatos por alguns dias e so retomar quando se sentir mais capaz.
  `;
  assert.equal(containsProhibitedDailyCompanionContent(unsafe), true);
});

test("aceita reflexao relacional que preserva escolha", () => {
  const safe = `
    Nem tudo precisa ser resolvido agora. Com o conflito em casa e a sobrecarga
    na escola acontecendo juntos, talvez seja util reconhecer que voce nao
    precisa resolver os dois ao mesmo tempo; decisoes maiores sobre a familia
    podem esperar ate ficar mais claro o que voce precisa dessa relacao.
  `;
  assert.equal(containsProhibitedDailyCompanionContent(safe), false);
});

test("humor so entra nas fontes quando existe pontuacao numerica", () => {
  assert.match(
    source,
    /typeof record\?\.como_sentiu === "number"/,
  );
  assert.doesNotMatch(
    source,
    /record\?\.como_sentiu !== null/,
  );
});

test("linguagem explicita de crise desvia antes da chamada ao modelo", () => {
  const crisisGate = source.indexOf("hasCrisisLanguage(context.diaryText)");
  const modelCall = source.indexOf("const generated = await requestMessage");
  assert.notEqual(crisisGate, -1);
  assert.notEqual(modelCall, -1);
  assert.ok(crisisGate < modelCall);
});
