# frozen_string_literal: true

class TranscriptionFilesSerializer
  include FastJsonapi::ObjectSerializer

  attribute :docket_number
  attribute :date_uploaded_aws
  attribute :file_name
  attribute :file_type
  attribute :aws_link_mp4
  attribute :aws_link_mp3
  attribute :aws_link_vtt
  attribute :aws_link_rtf
  attribute :file_status
end
