# frozen_string_literal: true

class CaseDistributionAuditLeverEntrySerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :case_distribution_lever_id, :created_at, :previous_value, :update_value
  attribute :user_name do |object|
    object.user.full_name
  end

  def as_json
    serializable_hash[:data][:attributes]
  end
end
