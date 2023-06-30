create or replace function caseflow_audit.add_row_to_vbms_communication_packages_audit() returns trigger
as
$add_row$
begin
  if (TG_OP = 'DELETE') then
    insert into caseflow_audit.vbms_communication_packages_audit
    select
      nextval('caseflow_audit.vbms_communication_packages_audit_id_seq'::regclass),
      'D',
      OLD.id,
      OLD.file_number,
      OLD.copies,
      OLD.status,
      OLD.comm_package_name,
      OLD.created_at,
      OLD.updated_at,
      OLD.document_mailable_via_pacman_id,
      OLD.document_mailable_via_pacman_type,
      OLD.created_by_id,
      OLD.updated_by_id,
      OLD.uuid;
  elsif (TG_OP = 'UPDATE') then
    insert into caseflow_audit.vbms_communication_packages_audit
    select
      nextval('caseflow_audit.vbms_communication_packages_audit_id_seq'::regclass),
      'U',
      NEW.id,
      NEW.file_number,
      NEW.copies,
      NEW.status,
      NEW.comm_package_name,
      NEW.created_at,
      NEW.updated_at,
      NEW.document_mailable_via_pacman_id,
      NEW.document_mailable_via_pacman_type,
      NEW.created_by_id,
      NEW.updated_by_id,
      NEW.uuid;
  elsif (TG_OP = 'INSERT') then
    insert into caseflow_audit.vbms_communication_packages_audit
    select
      nextval('caseflow_audit.vbms_communication_packages_audit_id_seq'::regclass),
      'I',
      NEW.id,
      NEW.file_number,
      NEW.copies,
      NEW.status,
      NEW.comm_package_name,
      NEW.created_at,
      NEW.updated_at,
      NEW.document_mailable_via_pacman_id,
      NEW.document_mailable_via_pacman_type,
      NEW.created_by_id,
      NEW.updated_by_id,
      NEW.uuid;
  end if;
  return null;
end;
$add_row$
language plpgsql;
