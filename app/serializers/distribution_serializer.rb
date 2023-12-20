# frozen_string_literal: true

class DistributionSerializer
  include FastJsonapi::ObjectSerializer

  attribute :distributed_cases_count
  attributes :id, :created_at, :updated_at, :status

  def as_json
    serializable_hash[:data][:attributes]
  end
end
