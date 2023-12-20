# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("CREATE OR REPLACE FUNCTION caseflow_audit.add_row_to_priority_end_product_sync_queue_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
begin
 if (TG_OP = 'DELETE') then
   insert into caseflow_audit.priority_end_product_sync_queue_audit
   select
     nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
     'D',
     OLD.id,
     OLD.end_product_establishment_id,
     OLD.batch_id,
     OLD.status,
     OLD.created_at,
     OLD.last_batched_at,
     CURRENT_TIMESTAMP,
     OLD.error_messages;
 elsif (TG_OP = 'UPDATE') then
   insert into caseflow_audit.priority_end_product_sync_queue_audit
   select
     nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
     'U',
     NEW.id,
     NEW.end_product_establishment_id,
     NEW.batch_id,
     NEW.status,
     NEW.created_at,
     NEW.last_batched_at,
     CURRENT_TIMESTAMP,
     NEW.error_messages;
 elsif (TG_OP = 'INSERT') then
   insert into caseflow_audit.priority_end_product_sync_queue_audit
   select
     nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
     'I',
     NEW.id,
     NEW.end_product_establishment_id,
     NEW.batch_id,
     NEW.status,
     NEW.created_at,
     NEW.last_batched_at,
     CURRENT_TIMESTAMP,
     NEW.error_messages;
 end if;
 return null;
end;
$function$
;")
conn.close
