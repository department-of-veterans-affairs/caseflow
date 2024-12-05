# frozen_string_literal: true

class TranscriptionPackageSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :task_number
  attribute :date_sent, &:formatted_date_upload_box
  attribute :return_date, &:formatted_returned_at
  attribute :status
  attribute :hearings, &:all_hearings
  attribute :contractor_name
  attribute :order_contents_count, &:contents_count
end
