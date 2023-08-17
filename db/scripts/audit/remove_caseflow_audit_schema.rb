# frozen_string_literal: true

require "pg"

begin
  conn = CaseflowRecord.connection
  conn.execute(
    "drop schema IF EXISTS caseflow_audit CASCADE;"
  )
  conn.close
rescue ActiveRecord::NoDatabaseError => error
  if error.message.include?('database "caseflow_certification_development" does not exist')
    puts "Database caseflow_certification_development does not exist; skipping make audit-remove"
  else
    raise error
  end
end
