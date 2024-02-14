# frozen_string_literal: true

require "pg"

begin
  conn = CaseflowRecord.connection

  # add_row_to_appeal_states_audit_table_function
  conn.execute(
    "create or replace function caseflow_audit.add_row_to_appeal_states_audit() returns trigger
    as
    $add_row$
    begin
      if (TG_OP = 'DELETE') then
        insert into caseflow_audit.appeal_states_audit
        select
          nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
          'D',
          OLD.id,
          OLD.appeal_cancelled,
          OLD.appeal_docketed,
          OLD.appeal_id,
          OLD.appeal_type,
          OLD.created_at,
          OLD.created_by_id,
          OLD.decision_mailed,
          OLD.hearing_postponed,
          OLD.hearing_scheduled,
          OLD.hearing_withdrawn,
          OLD.privacy_act_complete,
          OLD.privacy_act_pending,
          OLD.scheduled_in_error,
          OLD.updated_at,
          OLD.updated_by_id,
          OLD.vso_ihp_complete,
          OLD.vso_ihp_pending;
      elsif (TG_OP = 'UPDATE') then
        insert into caseflow_audit.appeal_states_audit
        select
          nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
          'U',
          NEW.id,
          NEW.appeal_cancelled,
          NEW.appeal_docketed,
          NEW.appeal_id,
          NEW.appeal_type,
          NEW.created_at,
          NEW.created_by_id,
          NEW.decision_mailed,
          NEW.hearing_postponed,
          NEW.hearing_scheduled,
          NEW.hearing_withdrawn,
          NEW.privacy_act_complete,
          NEW.privacy_act_pending,
          NEW.scheduled_in_error,
          NEW.updated_at,
          NEW.updated_by_id,
          NEW.vso_ihp_complete,
          NEW.vso_ihp_pending;
      elsif (TG_OP = 'INSERT') then
        insert into caseflow_audit.appeal_states_audit
        select
          nextval('caseflow_audit.appeal_states_audit_id_seq'::regclass),
          'I',
          NEW.id,
          NEW.appeal_cancelled,
          NEW.appeal_docketed,
          NEW.appeal_id,
          NEW.appeal_type,
          NEW.created_at,
          NEW.created_by_id,
          NEW.decision_mailed,
          NEW.hearing_postponed,
          NEW.hearing_scheduled,
          NEW.hearing_withdrawn,
          NEW.privacy_act_complete,
          NEW.privacy_act_pending,
          NEW.scheduled_in_error,
          NEW.updated_at,
          NEW.updated_by_id,
          NEW.vso_ihp_complete,
          NEW.vso_ihp_pending;
      end if;
      return null;
    end;
    $add_row$
    language plpgsql;"
  )

  # add_row_to_vbms_communication_packages_audit_table_function
  conn.execute(
    "create or replace function caseflow_audit.add_row_to_vbms_communication_packages_audit() returns trigger
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
    language plpgsql;"
  )

  # add_row_to_vbms_distributions_audit_table_function

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
          OLD.updated_by_id,
          OLD.uuid;
      elsif (TG_OP = 'UPDATE') then
        insert into caseflow_audit.vbms_distributions_audit
        select
          nextval('caseflow_audit.vbms_distributions_audit_id_seq'::regclass),
          'U',
          NEW.id,
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
          NEW.uuid;
      elsif (TG_OP = 'INSERT') then
        insert into caseflow_audit.vbms_distributions_audit
        select
          nextval('caseflow_audit.vbms_distributions_audit_id_seq'::regclass),
          'I',
          NEW.id,
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
          NEW.uuid;
      end if;
      return null;
    end;
    $add_row$
    language plpgsql;"
  )

  # add_row_to_vbms_distribution_destinations_audit_table_function

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

  # add_row_to_vbms_uploaded_documents_audit_table_function
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

  # add_row_to_priority_end_product_sync_queue_audit_table_function
  conn.execute("CREATE OR REPLACE FUNCTION caseflow_audit.add_row_to_priority_end_product_sync_queue_audit()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $function$
    begin
    if (TG_OP = 'DELETE') then
      insert into caseflow_audit.priority_end_product_sync_queue_audit
      select
        nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
        'D',
        OLD.id,
        OLD.end_product_establishment_id,
        OLD.batch_id,
        OLD.status,
        OLD.created_at,
        OLD.last_batched_at,
        CURRENT_TIMESTAMP,
        OLD.error_messages;
    elsif (TG_OP = 'UPDATE') then
      insert into caseflow_audit.priority_end_product_sync_queue_audit
      select
        nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
        'U',
        NEW.id,
        NEW.end_product_establishment_id,
        NEW.batch_id,
        NEW.status,
        NEW.created_at,
        NEW.last_batched_at,
        CURRENT_TIMESTAMP,
        NEW.error_messages;
    elsif (TG_OP = 'INSERT') then
      insert into caseflow_audit.priority_end_product_sync_queue_audit
      select
        nextval('caseflow_audit.priority_end_product_sync_queue_audit_id_seq'::regclass),
        'I',
        NEW.id,
        NEW.end_product_establishment_id,
        NEW.batch_id,
        NEW.status,
        NEW.created_at,
        NEW.last_batched_at,
        CURRENT_TIMESTAMP,
        NEW.error_messages;
    end if;
    return null;
    end;
    $function$
    ;")

  conn.close
rescue ActiveRecord::NoDatabaseError => error
  if error.message.include?('database "caseflow_certification_development" does not exist')
    STDOUT.puts "Database caseflow_certification_development does not exist; skipping make audit-remove"
  else
    raise error
  end
end
