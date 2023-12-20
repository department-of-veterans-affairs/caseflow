# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "drop table IF EXISTS public.vbms_ext_claim;"
)
conn.close

system("bundle exec rails r db/scripts/drop_pepsq_populate_trigger_from_vbms_ext_claim.rb")
