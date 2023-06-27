# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create or replace function caseflow_audit.add_row_to_vbms_distribution_destinations_audit() returns trigger
  as
  $add_row$
  begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.vbms_distribution_destinations_audit
      select
        nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass),
        'D',
        OLD.id,
        OLD.uuid,
        OLD.destination_type,
        OLD.address_line_1,
        OLD.address_line_2,
        OLD.address_line_3,
        OLD.address_line_4,
        OLD.address_line_5,
        OLD.address_line_6,
        OLD.treat_line_2_as_addressee,
        OLD.treat_line_3_as_addressee,
        OLD.city,
        OLD.state,
        OLD.postal_code,
        OLD.country_name,
        OLD.country_code,
        OLD.created_at,
        OLD.updated_at,
        OLD.vbms_distribution_id,
        OLD.created_by_id,
        OLD.updated_by_id;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.vbms_distribution_destinations_audit
      select
        nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass),
        'U',
        NEW.id,
        NEW.uuid,
        NEW.destination_type,
        NEW.address_line_1,
        NEW.address_line_2,
        NEW.address_line_3,
        NEW.address_line_4,
        NEW.address_line_5,
        NEW.address_line_6,
        NEW.treat_line_2_as_addressee,
        NEW.treat_line_3_as_addressee,
        NEW.city,
        NEW.state,
        NEW.postal_code,
        NEW.country_name,
        NEW.country_code,
        NEW.created_at,
        NEW.updated_at,
        NEW.vbms_distribution_id,
        NEW.created_by_id,
        NEW.updated_by_id;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.vbms_distribution_destinations_audit
      select
        nextval('caseflow_audit.vbms_distribution_destinations_audit_id_seq'::regclass),
        'I',
        NEW.id,
        NEW.uuid,
        NEW.destination_type,
        NEW.address_line_1,
        NEW.address_line_2,
        NEW.address_line_3,
        NEW.address_line_4,
        NEW.address_line_5,
        NEW.address_line_6,
        NEW.treat_line_2_as_addressee,
        NEW.treat_line_3_as_addressee,
        NEW.city,
        NEW.state,
        NEW.postal_code,
        NEW.country_name,
        NEW.country_code,
        NEW.created_at,
        NEW.updated_at,
        NEW.vbms_distribution_id,
        NEW.created_by_id,
        NEW.updated_by_id;
    end if;
    return null;
  end;
  $add_row$
  language plpgsql;"
)
conn.close
