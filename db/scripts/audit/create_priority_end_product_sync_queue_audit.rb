# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection
conn.execute("CREATE TABLE caseflow_audit.priority_end_product_sync_queue_audit (
              id bigserial primary key unique NOT null,
              type_of_change CHAR(1) not null,
              end_product_establishment_id bigint NOT null references end_product_establishments(id),
              batch_id uuid,
              status varchar(50) NOT null,
              created_at timestamp without time zone,
              last_batched_at timestamp without time zone,
              audit_created_at timestamp without time zone default now(),
              error_messages text[]
            );")
conn.close
