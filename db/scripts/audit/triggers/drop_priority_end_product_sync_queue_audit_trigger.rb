# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("DROP TRIGGER IF EXISTS priority_end_product_sync_queue_audit_trigger ON public.priority_end_product_sync_queue;")
conn.close
