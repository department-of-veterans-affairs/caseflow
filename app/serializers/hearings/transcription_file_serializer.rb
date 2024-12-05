# frozen_string_literal: true

class TranscriptionFileSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :docket_number
  attribute :hearing_type
  attribute :date_upload_aws
  attribute :date_returned_box
  attribute :file_name
  attribute :file_status
  attribute :file_type
end
