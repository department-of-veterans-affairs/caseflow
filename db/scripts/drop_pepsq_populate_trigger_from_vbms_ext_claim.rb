# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("
  drop trigger if exists update_claim_status_trigger on vbms_ext_claim;
  drop function if exists public.update_claim_status_trigger_function();
  ")

conn.close
