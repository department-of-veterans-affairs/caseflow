# frozen_string_literal: true

class Hearings::TranscriptionPackagesSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  # finalize these when we know the actual attribute names
  has_many :hearings
  has_many :legacy_hearings
  has_one :contractor

  attribute :task_number
  attribute :date_sent, &:created_at
  attribute :return_date, &:returned_at
  attribute :status
end
