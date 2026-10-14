-- AgroGestor v1.0: tabela de sincronização do protótipo HTML v0.9.
-- Execute APÓS o schema v1, no SQL Editor. Não apaga tabelas existentes.
-- O app armazena seu estado em JSON por usuário; as tabelas normalizadas
-- do schema v1 ainda não são utilizadas por esta versão.
create table if not exists public.agrogestor_states (
 user_id uuid primary key references auth.users(id) on delete cascade,
 payload jsonb not null default '{}'::jsonb,
 revision bigint not null default 0 check (revision >= 0),
 updated_at timestamptz not null default now(),
 constraint payload_object check (jsonb_typeof(payload)='object')
);
alter table public.agrogestor_states enable row level security;
revoke all on public.agrogestor_states from anon;
grant select on public.agrogestor_states to authenticated;
drop policy if exists agrogestor_state_read on public.agrogestor_states;
create policy agrogestor_state_read on public.agrogestor_states for select to authenticated
 using (user_id = (select auth.uid()));
-- Não permitir gravação direta; apenas a função transacional abaixo.
create or replace function public.save_agrogestor_state(expected_revision bigint,new_payload jsonb)
returns bigint language plpgsql security definer set search_path = '' as $$
declare u uuid := auth.uid(); r bigint;
begin
 if u is null then raise exception 'Autenticação necessária'; end if;
 if new_payload is null or jsonb_typeof(new_payload) <> 'object' then raise exception 'Dados inválidos'; end if;
 if octet_length(new_payload::text)>2000000 then raise exception 'Dados excedem 2 MB'; end if;
 insert into public.agrogestor_states(user_id,payload,revision)
 values (u,new_payload,1)
 on conflict (user_id) do update
 set payload=excluded.payload,revision=public.agrogestor_states.revision+1,updated_at=now()
 where public.agrogestor_states.revision=expected_revision
 returning revision into r;
 if r is null then raise exception 'Conflito de edição: os dados foram alterados em outro aparelho. Recarregue.'; end if;
 return r;
end $$;
revoke all on function public.save_agrogestor_state(bigint,jsonb) from public,anon;
grant execute on function public.save_agrogestor_state(bigint,jsonb) to authenticated;
