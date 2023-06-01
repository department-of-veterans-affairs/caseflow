# frozen_string_literal: true

##
# VbmsExtClaim records represents Vbms external claim records
##
class VbmsExtClaim < CaseflowRecord
  self.table_name = "vbms_ext_claim"
  self.primary_key = "CLAIM_ID"

  has_one :end_product_establishment, foreign_key: "reference_id", primary_key: "claim_id"

  alias_attribute :claim_id, :CLAIM_ID
  alias_attribute :claim_date, :CLAIM_DATE
  alias_attribute :ep_code, :EP_CODE
  alias_attribute :suspense_date, :SUSPENSE_DATE
  alias_attribute :suspense_reason_code, :SUSPENSE_REASON_CODE
  alias_attribute :suspense_reason_comments, :SUSPENSE_REASON_COMMENTS
  alias_attribute :claimant_person_id, :CLAIMANT_PERSON_ID
  alias_attribute :contention_count, :CONTENTION_COUNT
  alias_attribute :claim_soj, :CLAIM_SOJ
  alias_attribute :temporary_claim_soj, :TEMPORARY_CLAIM_SOJ
  alias_attribute :priority, :PRIORITY
  alias_attribute :type_code, :TYPE_CODE
  alias_attribute :lifecycle_status_name, :LIFECYCLE_STATUS_NAME
  alias_attribute :level_status_code, :LEVEL_STATUS_CODE
  alias_attribute :submitter_application_code, :SUBMITTER_APPLICATION_CODE
  alias_attribute :submitter_role_code, :SUBMITTER_ROLE_CODE
  alias_attribute :veteran_person_id, :VETERAN_PERSON_ID
  alias_attribute :establishment_date, :ESTABLISHMENT_DATE
  alias_attribute :intake_site, :INTAKE_SITE
  alias_attribute :payee_code, :PAYEE_CODE
  alias_attribute :sync_id, :SYNC_ID
  alias_attribute :createddt, :CREATEDDT
  alias_attribute :lastupdatedt, :LASTUPDATEDT
  alias_attribute :expirationdt, :EXPIRATIONDT
  alias_attribute :version, :VERSION
  alias_attribute :lifecycle_status_change_date, :LIFECYCLE_STATUS_CHANGE_DATE
  alias_attribute :rating_soj, :RATING_SOJ
  alias_attribute :program_type_code, :PROGRAM_TYPE_CODE
  alias_attribute :service_type_code, :SERVICE_TYPE_CODE
  alias_attribute :prevent_audit_trig, :PREVENT_AUDIT_TRIG
  alias_attribute :pre_discharge_type_code, :PRE_DISCHARGE_TYPE_CODE
  alias_attribute :pre_discharge_ind, :PRE_DISCHARGE_IND
  alias_attribute :organization_name, :ORGANIZATION_NAME
  alias_attribute :organization_soj, :ORGANIZATION_SOJ
  alias_attribute :allow_poa_access, :ALLOW_POA_ACCESS
  alias_attribute :poa_code, :POA_CODE
end
