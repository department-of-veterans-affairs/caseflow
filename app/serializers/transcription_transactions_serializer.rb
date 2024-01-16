# frozen_string_literal: true

class TranscriptionTransactionsSerializer
  include FastJsonapi::ObjectSerializer
  attribute :docket_number
  attribute :date_uploaded_aws
  attribute :file_name
  attribute :aws_link_mp4
  attribute :aws_link_mp3
  attribute :aws_link_vtt
  attribute :aws_link_rtf
  attribute :file_status

  def self.get_file_links(transcription_transactions, params)
    params[:file_links]
  end

  def self.get_docket_number(transcription_transactions, params)
    params[:docket_number]
  end

  def self.get_file_status(transcription_transactions, params)
    params[:file_status]
  end

  has_many :appeal_ids
end
