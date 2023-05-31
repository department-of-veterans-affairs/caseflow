# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "drop table IF EXISTS public.vbms_ext_claim;"
)
