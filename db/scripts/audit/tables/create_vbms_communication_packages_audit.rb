# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_communication_packages_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_communication_package_id bigint not null,
              uuid varchar NULL,
              file_number varchar NULL,
              copies int8 NULL DEFAULT 1,
              status varchar NULL,
              comm_package_name varchar NOT NULL,
              created_at timestamp NOT NULL,
              updated_at timestamp NOT NULL,
              vbms_uploaded_document_id int8 NULL,
              created_by_id int8 NULL,
              updated_by_id int8 NULL,
              pacman_uuid varchar NULL
            );")
conn.close
