# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
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
conn.close
