# frozen_string_literal: true

class CachedAppeal < CaseflowRecord
  self.table_name = "cached_appeal_attributes"

  # For convenience when working in the Rails console
  scope :ama_appeal, -> { where(appeal_type: "Appeal") }
  scope :legacy_appeal, -> { where(appeal_type: "LegacyAppeal") }
  scope :docket, ->(docket) { where(docket_type: docket) }
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: cached_appeal_attributes
#
#  appeal_type                  :string           indexed => [appeal_id]
#  case_type                    :string           indexed
#  closest_regional_office_city :string           indexed
#  closest_regional_office_key  :string           indexed
#  docket_number                :string
#  docket_type                  :string           indexed
#  former_travel                :boolean          indexed => [hearing_request_type]
#  hearing_request_type         :string(10)       indexed => [former_travel]
#  is_aod                       :boolean          indexed
#  issue_count                  :integer
#  power_of_attorney_name       :string           indexed
#  suggested_hearing_location   :string           indexed
#  veteran_name                 :string           indexed
#  created_at                   :datetime
#  updated_at                   :datetime         indexed
#  appeal_id                    :integer          indexed => [appeal_type]
#  vacols_id                    :string           indexed
#
