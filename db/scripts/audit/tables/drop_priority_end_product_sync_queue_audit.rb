# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("DROP TABLE IF EXISTS CASEFLOW_AUDIT.PRIORITY_END_PRODUCT_SYNC_QUEUE_AUDIT;")
conn.close
