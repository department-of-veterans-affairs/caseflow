# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("DROP FUNCTION IF EXISTS caseflow_audit.add_row_to_priority_end_product_sync_queue_audit();")
conn.close
