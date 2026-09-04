import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const source = readFileSync(new URL("./index.ts", import.meta.url), "utf8");

function relationshipDirective(): RegExp {
  const block = source.match(
    /const consequentialRelationshipDirective = new RegExp\(\s*\[([\s\S]*?)\]\.join\("\|"\),\s*"i",\s*\);/,
  );
  assert.notEqual(block, null);
  const patterns = [...block![1].matchAll(/String\.raw`([^`]*)`/g)]
    .map((match) => match[1]);
  assert.ok(patterns.length > 0);
  return new RegExp(patterns.join("|"), "i");
}

test("reflexao diaria pede orientacao concreta sem exercicios", () => {
  assert.match(source, /orientacao-reflexao personalizada/);
  assert.match(source, /A reflexao nao e um exercicio/);
  assert.match(source, /Os campos devem conter\s+somente texto simples/);
  assert.match(source, /cleanMarkdownMessage/);
  assert.match(source, /promptVersion = "daily-companion-v4"/);
  assert.match(source, /introduction: \{/);
  assert.match(source, /required: \["title", "introduction", "points"\]/);
  assert.match(source, /`- \*\*\$\{point\.label\}:\*\* \$\{point\.text\}`/);
  assert.match(source, /reflectionQuestion: null/);
  assert.match(source, /containsProhibitedDailyCompanionContent/);
});

test("servidor monta markdown a partir de campos simples", () => {
  assert.match(
    source,
    /title: \{\s+type: "string",\s+minLength: 3,\s+maxLength: 80,/,
  );
  assert.match(
    source,
    /introduction: \{\s+type: "string",\s+minLength: 20,\s+maxLength: 180,/,
  );
  assert.match(
    source,
    /points: \{\s+type: "array",\s+minItems: 1,\s+maxItems: 2,/,
  );
  assert.match(
    source,
    /label: \{\s+type: "string",\s+minLength: 2,\s+maxLength: 28,/,
  );
  assert.match(
    source,
    /text: \{\s+type: "string",\s+minLength: 12,\s+maxLength: 110,/,
  );
  assert.match(source, /cleanPlainField\(value\.introduction, 20, 180\)/);
  assert.match(source, /cleanPlainField\(valuePoint\.label, 2, 29\)/);
  assert.match(source, /cleanPlainField\(valuePoint\.text, 12, 110\)/);
  assert.match(source, /\/\[\*_`\\\[\\\]<>\]\//);
  assert.match(source, /daily_companion_model_output_invalid/);
});

test("bloqueia prescricao de afastamento da familia", () => {
  const unsafe = `
    Criar um limite temporario com a familia. Talvez seja util dizer a familia
    que vai reduzir contatos por alguns dias e so retomar quando se sentir mais capaz.
  `;
  assert.equal(relationshipDirective().test(unsafe), true);
});

test("aceita reflexao relacional que preserva escolha", () => {
  const safe = `
    Nem tudo precisa ser resolvido agora. Com o conflito em casa e a sobrecarga
    na escola acontecendo juntos, talvez seja util reconhecer que voce nao
    precisa resolver os dois ao mesmo tempo; decisoes maiores sobre a familia
    podem esperar ate ficar mais claro o que voce precisa dessa relacao.
  `;
  assert.equal(relationshipDirective().test(safe), false);
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
