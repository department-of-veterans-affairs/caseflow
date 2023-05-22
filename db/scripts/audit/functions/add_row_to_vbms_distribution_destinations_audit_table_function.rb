# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create or replace function caseflow_audit.add_row_to_vbms_distribution_destinations_audit() returns trigger
  as
  $add_row$
  begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.vbms_distribution_destinations_audit select nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass), 'D', OLD.*;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.vbms_distribution_destinations_audit select nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass), 'U', NEW.*;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.vbms_distribution_destinations_audit select nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass), 'I', NEW.*;
    end if;
    return null;
  end;
  $add_row$
  language plpgsql;"
)
conn.close
