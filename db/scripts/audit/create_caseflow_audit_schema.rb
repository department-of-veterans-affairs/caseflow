# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create schema caseflow_audit;")
