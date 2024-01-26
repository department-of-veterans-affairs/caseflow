# frozen_string_literal: true

class TranscriptionFileSerializer
  include FastJsonapi::ObjectSerializer

  attribute :docket_number
  attribute :date_upload_aws
  attribute :file_name
  attribute :file_type
  attribute :aws_link
  attribute :file_status
end
