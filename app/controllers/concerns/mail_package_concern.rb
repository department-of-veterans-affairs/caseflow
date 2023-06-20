# frozen_string_literal: true

module MailPackageConcern
  extend ActiveSupport::Concern

  included do
    def recipient_info
      params[:recipient_info]
    end

    def build_mail_package
      return if recipient_info.blank?

      throw_error_if_copies_out_of_range
      # Create and validate MailRequest objects, save to db, and store distribution IDs
      mail_requests.map do |request|
        request.call
        distribution_ids << request.vbms_distribution_id
      end
    end

    # Payload with distributions value (array of JSON-formatted MailRequest objects) and copies (integer)
    def mail_package
      return nil if recipient_info.blank?

      { distributions: mail_requests.to_json, copies: copies }
    end
  end

  private

  def copies
    # Default value of 1 for copies
    return 1 if params[:copies].blank?

    params[:copies]
  end

  def mail_requests
    @mail_requests ||= create_mail_requests_and_track_errors
  end

  def create_mail_requests_and_track_errors
    requests = recipient_info.map.with_index do |recipient, idx|
      MailRequest.new(recipient).tap do |request|
        if request.invalid?
          recipient_errors["distribution #{idx + 1}"] = request.errors.full_messages.join(", ")
        end
      end
    end
    throw_error_if_recipient_info_invalid
    requests
  end

  def recipient_errors
    @recipient_errors ||= {}
  end

  def distribution_ids
    @distribution_ids ||= []
  end

  def throw_error_if_copies_out_of_range
    unless (1..500).cover?(copies)
      fail Caseflow::Error::MissingRecipientInfo, "Copies must be between 1 and 500 (inclusive)".to_json
    end
  end

  def throw_error_if_recipient_info_invalid
    return unless recipient_errors.any?

    fail Caseflow::Error::MissingRecipientInfo, recipient_errors.to_json
  end
end
