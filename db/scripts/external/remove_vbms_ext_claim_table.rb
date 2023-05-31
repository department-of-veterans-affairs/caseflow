# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection

conn.execute("drop table if exists public.vbms_ext_claim;")
