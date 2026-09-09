-- A reflexao precisa de espaco para frases completas em cada item.
begin;

alter table public.mensagens_diarias_ia
  drop constraint if exists iris_mensagem_diaria_texto_valido;
alter table public.mensagens_diarias_ia
  add constraint iris_mensagem_diaria_texto_valido check (
    char_length(btrim(mensagem)) between 20 and 1200
  );

-- Reflexoes antigas nao passaram pelo contrato de texto completo e apoio humano.
-- A funcao so reutiliza o cache da versao atual, sem apagar o historico aqui.
alter table public.mensagens_diarias_ia
  add column if not exists versao_prompt text;

notify pgrst, 'reload schema';
commit;
