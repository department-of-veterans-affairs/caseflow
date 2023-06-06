# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create trigger priority_end_product_sync_queue_audit_trigger
  after insert or update or delete on public.priority_end_product_sync_queue
  for each row
  execute procedure caseflow_audit.add_row_to_priority_end_product_sync_queue_audit();"
)
conn.close
