# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_distributions_audit (
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
              updated_by_id int8 NULL
            );")
conn.close
