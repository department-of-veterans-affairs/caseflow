# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_distribution_destinations_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_distribution_destinations_id bigint not null,
              address_line_1 varchar NOT NULL,
              address_line_2 varchar NOT NULL,
              address_line_3 varchar NOT NULL,
              address_line_4 varchar NULL,
              address_line_5 varchar NULL,
              address_line_6 varchar NULL,
              city varchar NOT NULL,
              country_code varchar NOT NULL,
              country_name varchar NOT NULL,
              created_at timestamp NOT NULL,
              created_by_id int8 NULL,
              destination_type varchar NOT NULL,
              email_address varchar NOT NULL,
              phone_number varchar NOT NULL,
              postal_code varchar NOT NULL,
              state varchar NOT NULL,
              treat_line_2_as_addressee bool NOT NULL,
              treat_line_3_as_addressee bool NULL,
              updated_at timestamp NOT NULL,
              updated_by_id int8 NULL,
              vbms_distribution_id int8 NULL
            );")
