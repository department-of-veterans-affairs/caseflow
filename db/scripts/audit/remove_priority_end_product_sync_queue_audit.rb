# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("drop table if exists caseflow_audit.priority_end_product_sync_queue_audit;")
