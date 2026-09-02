-- Mantem a reflexao diaria coerente com o contexto estruturado do dia.
-- Alterar somente a pontuacao de humor deve invalidar a mensagem anterior do
-- mesmo modo que editar ou apagar o texto do diario.

create or replace function public.iris_invalidar_mensagem_diaria_ao_mudar_diario()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if old.diario_emocional is distinct from new.diario_emocional
     or old.como_sentiu is distinct from new.como_sentiu then
    delete from public.mensagens_diarias_ia
     where paciente_id = new.paciente_id
       and data_local = new.data_local;
  end if;
  return new;
end;
$$;

drop trigger if exists iris_invalidar_mensagem_diaria_ao_mudar_diario
  on public.registros_emocionais;
create trigger iris_invalidar_mensagem_diaria_ao_mudar_diario
  after update of diario_emocional, como_sentiu
  on public.registros_emocionais
  for each row execute function public.iris_invalidar_mensagem_diaria_ao_mudar_diario();

notify pgrst, 'reload schema';
