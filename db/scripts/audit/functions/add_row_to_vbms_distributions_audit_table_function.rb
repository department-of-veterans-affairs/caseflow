# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create or replace function caseflow_audit.add_row_to_vbms_distributions_audit() returns trigger
  as
  $add_row$
  begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.vbms_distributions_audit
      select
        nextval('caseflow_audit.vbms_distributions_audit_id_seq'::regclass),
        'D',
        OLD.id,
        OLD.uuid,
        OLD.recipient_type,
        OLD.name,
        OLD.first_name,
        OLD.middle_name,
        OLD.last_name,
        OLD.participant_id,
        OLD.poa_code,
        OLD.claimant_station_of_jurisdiction,
        OLD.created_at,
        OLD.updated_at,
        OLD.vbms_communication_package_id,
        OLD.created_by_id,
        OLD.updated_by_id
        OLD.pacman_uuid;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.vbms_distributions_audit
      select
        nextval('caseflow_audit.vbms_distributions_audit_id_seq'::regclass),
        'U',
        NEW.id,
        NEW.uuid,
        NEW.recipient_type,
        NEW.name,
        NEW.first_name,
        NEW.middle_name,
        NEW.last_name,
        NEW.participant_id,
        NEW.poa_code,
        NEW.claimant_station_of_jurisdiction,
        NEW.created_at,
        NEW.updated_at,
        NEW.vbms_communication_package_id,
        NEW.created_by_id,
        NEW.updated_by_id,
        NEW.pacman_uuid;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.vbms_distributions_audit
      select
        nextval('caseflow_audit.vbms_distributions_audit_id_seq'::regclass),
        'I',
        NEW.id,
        NEW.uuid,
        NEW.recipient_type,
        NEW.name,
        NEW.first_name,
        NEW.middle_name,
        NEW.last_name,
        NEW.participant_id,
        NEW.poa_code,
        NEW.claimant_station_of_jurisdiction,
        NEW.created_at,
        NEW.updated_at,
        NEW.vbms_communication_package_id,
        NEW.created_by_id,
        NEW.updated_by_id,
        NEW.pacman_uuid;
    end if;
    return null;
  end;
  $add_row$
  language plpgsql;"
)
conn.close
