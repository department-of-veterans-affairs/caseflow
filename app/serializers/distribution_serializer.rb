# frozen_string_literal: true

class DistributionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :distributed_cases_count
  attributes :id, :created_at, :updated_at, :status
  attribute :distribution_stats, if: proc { !Rails.in_upper_env? }

  def as_json
    serializable_hash[:data][:attributes]
  end
end
