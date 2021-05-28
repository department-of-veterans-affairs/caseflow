# frozen_string_literal: true

class CachedAppeal < CaseflowRecord
  self.table_name = "cached_appeal_attributes"

  # For convenience when working in the Rails console
  scope :ama_appeal, -> { where(appeal_type: "Appeal") }
  scope :legacy_appeal, -> { where(appeal_type: "LegacyAppeal") }
  scope :docket, ->(docket) { where(docket_type: docket) }
end
