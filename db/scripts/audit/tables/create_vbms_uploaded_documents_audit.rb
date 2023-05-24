# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_uploaded_documents_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_uploaded_documents_id bigint not null,
              appeal_id int8 NULL,
              appeal_type varchar NULL,
              attempted_at timestamp NULL,
              canceled_at timestamp NULL,
              created_at timestamp NOT NULL,
              document_name varchar NULL,
              document_subject varchar NULL,
              document_type varchar NOT NULL,
              error varchar NULL,
              last_submitted_at timestamp NULL,
              processed_at timestamp NULL,
              submitted_at timestamp NULL,
              updated_at timestamp NOT NULL,
              uploaded_to_vbms_at timestamp NULL,
              veteran_file_number varchar NULL
            );")
conn.close
