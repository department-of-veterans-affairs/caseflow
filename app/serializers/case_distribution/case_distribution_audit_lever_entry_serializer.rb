# frozen_string_literal: true

class CaseDistributionAuditLeverEntrySerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :case_distribution_lever_id, :created_at, :previous_value, :update_value

  attribute :user_css_id do |object|
    object.user.css_id
  end

  attribute :user_name do |object|
    object.user.full_name
  end

  attribute :lever_title do |object|
    object.case_distribution_lever.title
  end

  attribute :lever_data_type do |object|
    object.case_distribution_lever.data_type
  end

  attribute :lever_unit do |object|
    object.case_distribution_lever.unit
  end

  def as_json
    serializable_hash[:data][:attributes]
  end
end
