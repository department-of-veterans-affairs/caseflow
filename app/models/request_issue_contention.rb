# frozen_string_literal: true

class RequestIssueContention
  def initialize(request_issue)
    @request_issue = request_issue
  end

  delegate :contention_reference_id, :contention_removed_at, :contention_updated_at,
           :edited_description, to: :request_issue

  def vbms_contention
    return unless contention_reference_id

    request_issue.contention
  end

  def update_text!
    return unless contention_reference_id && contention_text_update_pending

    # if Vbms_contention is nil, then it will give the ContentionNotFound error message
    unless vbms_contention
      Raven.capture_exception(
        "ContentionNotFound: Contention reference id #{contention_reference_id}"
      )
      Rails.logger.error("ContentionNotFound: Contention reference id #{contention_reference_id}")
      fail EndProductEstablishment::ContentionNotFound, contention_reference_id
    end

    contention_to_update = vbms_contention
    contention_to_update.text = Contention.new(edited_description).text
    VBMSService.update_contention!(contention_to_update)
    request_issue.update!(contention_updated_at: Time.zone.now)
  end

  def remove!
    VBMSService.remove_contention!(vbms_contention) if vbms_contention
    request_issue.update!(contention_removed_at: Time.zone.now)
  end

  private

  def contention_text_update_pending
    edited_description && contention_updated_at.nil?
  end

  attr_reader :request_issue
end
