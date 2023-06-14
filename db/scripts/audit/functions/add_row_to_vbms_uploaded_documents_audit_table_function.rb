# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute(
  "create or replace function caseflow_audit.add_row_to_vbms_uploaded_documents_audit() returns trigger
  as
  $add_row$
  begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.vbms_uploaded_documents_audit
      select
        nextval('caseflow_audit.vbms_uploaded_documents_audit_id_seq'::regclass),
        'D',
        OLD.id,
        OLD.appeal_id,
        OLD.appeal_type,
        OLD.attempted_at,
        OLD.canceled_at,
        OLD.created_at,
        OLD.document_name,
        OLD.document_series_reference_id,
        OLD.document_subject,
        OLD.document_type,
        OLD.document_version_reference_id,
        OLD.error,
        OLD.last_submitted_at,
        OLD.processed_at,
        OLD.submitted_at,
        OLD.updated_at,
        OLD.uploaded_to_vbms_at,
        OLD.veteran_file_number;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.vbms_uploaded_documents_audit
      select
        nextval('caseflow_audit.vbms_uploaded_documents_audit_id_seq'::regclass),
        'U',
        NEW.id,
        NEW.appeal_id,
        NEW.appeal_type,
        NEW.attempted_at,
        NEW.canceled_at,
        NEW.created_at,
        NEW.document_name,
        NEW.document_series_reference_id,
        NEW.document_subject,
        NEW.document_type,
        NEW.document_version_reference_id,
        NEW.error,
        NEW.last_submitted_at,
        NEW.processed_at,
        NEW.submitted_at,
        NEW.updated_at,
        NEW.uploaded_to_vbms_at,
        NEW.veteran_file_number;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.vbms_uploaded_documents_audit
      select
        nextval('caseflow_audit.vbms_uploaded_documents_audit_id_seq'::regclass),
        'I',
        NEW.id,
        NEW.appeal_id,
        NEW.appeal_type,
        NEW.attempted_at,
        NEW.canceled_at,
        NEW.created_at,
        NEW.document_name,
        NEW.document_series_reference_id,
        NEW.document_subject,
        NEW.document_type,
        NEW.document_version_reference_id,
        NEW.error,
        NEW.last_submitted_at,
        NEW.processed_at,
        NEW.submitted_at,
        NEW.updated_at,
        NEW.uploaded_to_vbms_at,
        NEW.veteran_file_number;
    end if;
    return null;
  end;
  $add_row$
  language plpgsql;"
)
conn.close
