# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create trigger vbms_distribution_destinations_audit_trigger
  after insert or update or delete on public.vbms_distribution_destinations
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distribution_destinations_audit();"
)
conn.close
