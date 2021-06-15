# frozen_string_literal: true

class Api::V3::LegacyAppealSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower
  set_id :vacols_id

  attribute :issues do |object|
    object.issues.map do |issue|
      Api::V3::LegacyRelatedIssueSerializer.new(issue).serializable_hash[:data][:attributes]
    end
  end

  attribute :veteran_full_name
  attribute :decision_date
  attribute :latest_soc_ssoc_date do |object|
    ([object&.soc_date] + object&.ssoc_dates).max
  end
end
