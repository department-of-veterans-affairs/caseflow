# frozen_string_literal: true

require "pg"

conn = CaseflowRecord.connection

# appeal_states_audit_trigger
conn.execute(
  "create trigger appeal_states_audit_trigger
  after insert or update or delete on public.appeal_states
  for each row
  execute procedure caseflow_audit.add_row_to_appeal_states_audit();"
)

# create_vbms_communication_packages_audit_trigger

conn.execute(
  "create trigger vbms_communication_packages_audit_trigger
  after insert or update or delete on public.vbms_communication_packages
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_communication_packages_audit();"
)

# create_vbms_distributions_audit_trigger

conn.execute(
  "create trigger vbms_distributions_audit_trigger
  after insert or update or delete on public.vbms_distributions
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distributions_audit();"
)

# create_vbms_distribution_destinations_audit_trigger

conn.execute(
  "create trigger vbms_distribution_destinations_audit_trigger
  after insert or update or delete on public.vbms_distribution_destinations
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_distribution_destinations_audit();"
)

# create_vbms_uploaded_documents_audit_trigger

conn.execute(
  "create trigger vbms_uploaded_documents_audit_trigger
  after insert or update or delete on public.vbms_uploaded_documents
  for each row
  execute procedure caseflow_audit.add_row_to_vbms_uploaded_documents_audit();"
)

# create_priority_end_product_sync_queue_audit_trigger
conn.execute(
  "create trigger priority_end_product_sync_queue_audit_trigger
  after insert or update or delete on public.priority_end_product_sync_queue
  for each row
  execute procedure caseflow_audit.add_row_to_priority_end_product_sync_queue_audit();"
)
conn.close
