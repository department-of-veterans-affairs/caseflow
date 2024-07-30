# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection

# appeal_states_audit_trigger
conn.execute(
  "create trigger appeal_states_audit_trigger
  after insert or update or delete on public.appeal_states
  for each row
  execute procedure caseflow_audit.add_row_to_appeal_states_audit();"
)

# create_vbms_communication_packages_audit_trigger

conn.execute(
  "create trigger vbms_communication_packages_audit_trigger
  after insert or update or delete on public.vbms_communication_packages
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_communication_packages_audit();"
)

# create_vbms_distributions_audit_trigger

conn.execute(
  "create trigger vbms_distributions_audit_trigger
  after insert or update or delete on public.vbms_distributions
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distributions_audit();"
)

# create_vbms_distribution_destinations_audit_trigger

conn.execute(
  "create trigger vbms_distribution_destinations_audit_trigger
  after insert or update or delete on public.vbms_distribution_destinations
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distribution_destinations_audit();"
)

# create_vbms_uploaded_documents_audit_trigger

conn.execute(
  "create trigger vbms_uploaded_documents_audit_trigger
  after insert or update or delete on public.vbms_uploaded_documents
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_uploaded_documents_audit();"
)

# create_priority_end_product_sync_queue_audit_trigger
conn.execute(
  "create trigger priority_end_product_sync_queue_audit_trigger
  after insert or update or delete on public.priority_end_product_sync_queue
  for each row
  execute procedure caseflow_audit.add_row_to_priority_end_product_sync_queue_audit();"
)

# add_pepsq_populate_trigger_to_vbms_ext_claim.rb
conn.execute("
  drop trigger if exists update_claim_status_trigger on vbms_ext_claim;

  create or replace function public.update_claim_status_trigger_function()
  returns trigger as $$
    declare
      string_claim_id varchar(25);
      epe_id integer;
    begin
      if (NEW.\"EP_CODE\" LIKE '04%'
          OR NEW.\"EP_CODE\" LIKE '03%'
          OR NEW.\"EP_CODE\" LIKE '93%'
          OR NEW.\"EP_CODE\" LIKE '68%')
          and (NEW.\"LEVEL_STATUS_CODE\" = 'CLR' OR NEW.\"LEVEL_STATUS_CODE\" = 'CAN') then

        string_claim_id := cast(NEW.\"CLAIM_ID\" as varchar);

        select id into epe_id
        from end_product_establishments
        where (reference_id = string_claim_id
        and (synced_status is null or synced_status <> NEW.\"LEVEL_STATUS_CODE\"));

        if epe_id > 0
        then
          if not exists (
            select 1
            from priority_end_product_sync_queue
            where end_product_establishment_id = epe_id
          ) then
            insert into priority_end_product_sync_queue (created_at, end_product_establishment_id, updated_at)
            values (now(), epe_id, now());
          end if;
        end if;
      end if;
      return null;
    end;
  $$
  language plpgsql;

  create trigger update_claim_status_trigger
  after update or insert on vbms_ext_claim
  for each row
  execute procedure public.update_claim_status_trigger_function();
  ")

conn.close
