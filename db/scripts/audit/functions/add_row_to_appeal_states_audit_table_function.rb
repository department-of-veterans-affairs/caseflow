# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create or replace function caseflow_audit.add_row_to_appeal_states_audit() returns trigger
  as
  $appeal_states_audit$
  begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.appeal_states_audit select nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass), 'D', OLD.*;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.appeal_states_audit select nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass), 'U', NEW.*;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.appeal_states_audit select nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass), 'I', NEW.*;
    end if;
    return null;
  end;
  $appeal_states_audit$
  language plpgsql;"
)
conn.close
