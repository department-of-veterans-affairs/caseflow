# frozen_string_literal: true

class RequestIssueContention
  def initialize(request_issue)
    @request_issue = request_issue
  end

  delegate :end_product_establishment, :contention_reference_id, :contention_removed_at, :contention_updated_at,
           :edited_description, to: :request_issue

  def vbms_contention
    return unless contention_reference_id

    end_product_establishment.contention_for_object(request_issue)
  end

  def update_text!
    return unless contention_text_update_pending

    fail EndProductEstablishment::ContentionNotFound, contention_reference_id unless vbms_contention

    contention_to_update = vbms_contention
    contention_to_update.text = Contention.new(edited_description).text
    VBMSService.update_contention!(contention_to_update)
    request_issue.update!(contention_updated_at: Time.zone.now)
  end

  def remove!
    fail EndProductEstablishment::ContentionNotFound, contention_reference_id unless vbms_contention

    VBMSService.remove_contention!(vbms_contention)
    request_issue.update!(contention_removed_at: Time.zone.now)
  end

  private

  def contention_text_update_pending
    edited_description && contention_updated_at.nil?
  end

  attr_reader :request_issue
end
