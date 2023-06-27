# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_distribution_destinations_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_distribution_destinations_id bigint not null,
              destination_type varchar NOT NULL,
              address_line_1 varchar NOT NULL,
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
              email_address varchar NULL,
              phone_number varchar NULL,
              created_at timestamp NOT NULL,
              updated_at timestamp NOT NULL,
              vbms_distribution_id int8 NULL,
              created_by_id int8 NULL,
              updated_by_id int8 NULL,
              pacman_uuid varchar NULL
            );")
conn.close
