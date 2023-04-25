# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("create table caseflow_audit.vbms_distribution_destinations_audit (
              id BIGSERIAL PRIMARY KEY,
              type_of_change CHAR(1) not null,
              vbms_distribution_destinations_id bigint not null,
              DATA FROM TABLE...
            );")
