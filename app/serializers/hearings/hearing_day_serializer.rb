# frozen_string_literal: true

class HearingDaySerializer
  include FastJsonapi::ObjectSerializer

  attribute :bva_poc
  attribute :created_at
  attribute :created_by_id
  attribute :deleted_at
  attribute :id
  attribute :judge_first_name
  attribute :judge_id
  attribute :judge_last_name
  attribute :lock
  attribute :notes
  attribute :readable_request_type
  attribute :regional_office
  attribute :request_type
  attribute :room
  attribute :scheduled_for
  attribute :total_slots
  attribute :updated_by_id
  attribute :updated_at
end
