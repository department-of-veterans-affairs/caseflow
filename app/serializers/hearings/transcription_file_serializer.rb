# frozen_string_literal: true

class TranscriptionFileSerializer
  include FastJsonapi::ObjectSerializer

  attribute :date_upload_aws
  attribute :file_name
  attribute :aws_link
  attribute :file_status
end
