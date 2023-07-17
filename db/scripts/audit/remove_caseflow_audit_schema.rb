# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "drop schema IF EXISTS caseflow_audit CASCADE;"
)
conn.close
