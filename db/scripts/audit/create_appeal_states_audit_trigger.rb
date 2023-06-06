# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create trigger appeal_states_audit_trigger
  after insert or update or delete on public.appeal_states
  for each row
  execute procedure caseflow_audit.add_row_to_appeal_states_audit();"
)
