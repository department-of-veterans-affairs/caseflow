# frozen_string_literal: true

# removes caseflow_audit schema, remove vhms_ext table and other triggers and
# recreate new schemas.

require "pg"

conn = CaseflowRecord.connection

begin
  # audit-removed
  conn.execute(
    "drop schema IF EXISTS caseflow_audit CASCADE;"
  )

  # remove_vbms_ext_claim_table.rb
  conn.execute(
    "drop table IF EXISTS public.vbms_ext_claim;"
  )

  # drop trigger and function
  conn.execute("
    drop trigger if exists update_claim_status_trigger on vbms_ext_claim;
    drop function if exists public.update_claim_status_trigger_function();
  ")
rescue ActiveRecord::NoDatabaseError => error
  if error.message.include?('database "caseflow_certification_development" does not exist')
    STDOUT.puts "Database caseflow_certification_development does not exist; \
    Error during dropping table/triggers/function create_bulk_audit_script."
  else
    raise error
  end
end

conn.execute("create schema caseflow_audit;")

conn.execute("create table caseflow_audit.appeal_states_audit (
            id BIGSERIAL PRIMARY KEY,
            type_of_change CHAR(1) not null,
            appeal_states_id bigint not null,
            appeal_cancelled boolean not null,
            appeal_docketed boolean not null,
            appeal_id BIGINT not null,
            appeal_type VARCHAR not null,
            created_at timestamp not null,
            created_by_id bigint not null,
            decision_mailed boolean not null,
            hearing_postponed boolean not null,
            hearing_scheduled boolean not null,
            hearing_withdrawn boolean not null,
            privacy_act_complete boolean not null,
            privacy_act_pending boolean not null,
            scheduled_in_error boolean not null,
            updated_at timestamp,
            updated_by_id bigint,
            vso_ihp_complete boolean not null,
            vso_ihp_pending boolean not null
          );")
# create_vbms_communication_packages_audit

conn.execute(
  "create table caseflow_audit.vbms_communication_packages_audit
    (
      id BIGSERIAL PRIMARY KEY,
      type_of_change CHAR(1) not null,
      vbms_communication_package_id bigint not null,
      file_number varchar NULL,
      copies int8 NULL DEFAULT 1,
      status varchar NULL,
      comm_package_name varchar NOT NULL,
      created_at timestamp NOT NULL,
      updated_at timestamp NOT NULL,
      document_mailable_via_pacman_id bigint not NULL,
      document_mailable_via_pacman_type varchar not NULL,
      created_by_id int8 NULL,
      updated_by_id int8 NULL,
      uuid varchar NULL
    );"
)

conn.execute(
  "create table caseflow_audit.vbms_distributions_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_distributions_id bigint not null,
              recipient_type varchar NOT NULL,
              name varchar NULL,
              first_name varchar NULL,
              middle_name varchar NULL,
              last_name varchar NULL,
              participant_id varchar NULL,
              poa_code varchar NULL,
              claimant_station_of_jurisdiction varchar NULL,
              created_at timestamp NOT NULL,
              updated_at timestamp NOT NULL,
              vbms_communication_package_id int8 NULL,
              created_by_id int8 NULL,
              updated_by_id int8 NULL,
              uuid varchar NULL
            );"
)

# create_vbms_distribution_destinations_audit
conn.execute(
  "create table caseflow_audit.vbms_distribution_destinations_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_distribution_destinations_id bigint not null,
              destination_type varchar NOT NULL,
              address_line_1 varchar NULL,
              address_line_2 varchar NULL,
              address_line_3 varchar NULL,
              address_line_4 varchar NULL,
              address_line_5 varchar NULL,
              address_line_6 varchar NULL,
              treat_line_2_as_addressee bool NULL,
              treat_line_3_as_addressee bool NULL,
              city varchar NULL,
              state varchar NULL,
              postal_code varchar NULL,
              country_name varchar NULL,
              country_code varchar NULL,
              created_at timestamp NOT NULL,
              updated_at timestamp NOT NULL,
              vbms_distribution_id int8 NULL,
              created_by_id int8 NULL,
              updated_by_id int8 NULL
            );"
)

# vbms_uploaded_documents_audit
conn.execute(
  "create table caseflow_audit.vbms_uploaded_documents_audit (
            id BIGSERIAL PRIMARY KEY,
            type_of_change CHAR(1) not null,
            vbms_uploaded_documents_id bigint not null,
            appeal_id int8 NULL,
            appeal_type varchar NULL,
            attempted_at timestamp NULL,
            canceled_at timestamp NULL,
            created_at timestamp NOT NULL,
            document_name varchar NULL,
            document_series_reference_id varchar NULL,
            document_subject varchar NULL,
            document_type varchar NOT NULL,
            document_version_reference_id varchar NULL,
            error varchar NULL,
            last_submitted_at timestamp NULL,
            processed_at timestamp NULL,
            submitted_at timestamp NULL,
            updated_at timestamp NOT NULL,
            uploaded_to_vbms_at timestamp NULL,
            veteran_file_number varchar NULL
          );"
)

# PRIORITY_END_PRODUCT_SYNC_QUEUE_AUDIT
conn.execute("CREATE TABLE CASEFLOW_AUDIT.PRIORITY_END_PRODUCT_SYNC_QUEUE_AUDIT (
            ID BIGSERIAL PRIMARY KEY UNIQUE NOT NULL,
            TYPE_OF_CHANGE CHAR(1) NOT NULL,
            PRIORITY_END_PRODUCT_SYNC_QUEUE_ID BIGINT NOT NULL,
            END_PRODUCT_ESTABLISHMENT_ID BIGINT NOT NULL REFERENCES END_PRODUCT_ESTABLISHMENTS(ID),
            BATCH_ID UUID REFERENCES BATCH_PROCESSES(BATCH_ID),
            STATUS VARCHAR(50) NOT NULL,
            CREATED_AT TIMESTAMP WITHOUT TIME ZONE,
            LAST_BATCHED_AT TIMESTAMP WITHOUT TIME ZONE,
            AUDIT_CREATED_AT TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
            ERROR_MESSAGES TEXT[]
          );")

# Create vbms_ext_claim file -> aka external-db-create
conn.execute('CREATE TABLE IF NOT EXISTS public.vbms_ext_claim (
          "CLAIM_ID" numeric(38,0) primary key unique NOT null,
          "CLAIM_DATE" timestamp without time zone,
          "EP_CODE" character varying(25),
          "SUSPENSE_DATE" timestamp without time zone,
          "SUSPENSE_REASON_CODE" character varying(25),
          "SUSPENSE_REASON_COMMENTS" character varying(1000),
          "CLAIMANT_PERSON_ID" numeric(38,0),
          "CONTENTION_COUNT" integer,
          "CLAIM_SOJ" character varying(25),
          "TEMPORARY_CLAIM_SOJ" character varying(25),
          "PRIORITY" character varying(10),
          "TYPE_CODE" character varying(25),
          "LIFECYCLE_STATUS_NAME" character varying(50),
          "LEVEL_STATUS_CODE" character varying(25),
          "SUBMITTER_APPLICATION_CODE" character varying(25),
          "SUBMITTER_ROLE_CODE" character varying(25),
          "VETERAN_PERSON_ID" numeric(15,0),
          "ESTABLISHMENT_DATE" timestamp without time zone,
          "INTAKE_SITE" character varying(25),
          "PAYEE_CODE" character varying(25),
          "SYNC_ID" numeric(38,0) NOT null,
          "CREATEDDT" timestamp without time zone NOT null default NULL,
          "LASTUPDATEDT" timestamp without time zone NOT null default NULL,
          "EXPIRATIONDT" timestamp without time zone,
          "VERSION" numeric(38,0) NOT null default NULL,
          "LIFECYCLE_STATUS_CHANGE_DATE" timestamp without time zone,
          "RATING_SOJ" character varying(25),
          "PROGRAM_TYPE_CODE" character varying(10),
          "SERVICE_TYPE_CODE" character varying(10),
          "PREVENT_AUDIT_TRIG" smallint NOT null default 0,
          "PRE_DISCHARGE_TYPE_CODE" character varying(10),
          "PRE_DISCHARGE_IND" character varying(5),
          "ORGANIZATION_NAME" character varying(100),
          "ORGANIZATION_SOJ" character varying(25),
          "ALLOW_POA_ACCESS" character varying(5),
          "POA_CODE" character varying(25)
);')

conn.execute('CREATE INDEX IF NOT EXISTS claim_id_index ON public.vbms_ext_claim ("CLAIM_ID")')
conn.execute('CREATE INDEX IF NOT EXISTS level_status_code_index ON public.vbms_ext_claim ("LEVEL_STATUS_CODE")')

conn.close
