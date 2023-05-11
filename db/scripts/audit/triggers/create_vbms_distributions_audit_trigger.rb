# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create trigger vbms_distributions_audit_trigger
  after insert or update or delete on public.vbms_distributions
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distributions_audit();"
)
conn.close
