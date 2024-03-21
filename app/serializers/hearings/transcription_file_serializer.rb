# frozen_string_literal: true

class TranscriptionFileSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :date_upload_aws
  attribute :file_name
  attribute :file_status
  attribute :file_type
end
