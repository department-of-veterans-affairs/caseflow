# frozen_string_literal: true

class CaseSearchResultsBase
  include ActiveModel::Validations

  validate :vso_employee_has_access

  def initialize(user:)
    @user = user
  end

  def call
    @success = valid?

    search_results if success

    FormResponse.new(
      success: success,
      errors: errors.messages[:workflow],
      extra: error_status_or_search_results
    )
  end

  protected

  attr_reader :status, :user

  def current_user_is_vso_employee?
    user.vso_employee?
  end

  def veterans_user_can_access
    @veterans_user_can_access ||= veterans.select { |veteran| access?(veteran.file_number) }
  end

  def json_appeals(appeals)
    ama_appeals, legacy_appeals = appeals.partition { |appeal| appeal.is_a?(Appeal) }

    ama_hash = WorkQueue::AppealSerializer.new(
      ama_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    legacy_hash = WorkQueue::LegacyAppealSerializer.new(
      legacy_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    ama_hash[:data].concat(legacy_hash[:data])
  end

  private

  attr_reader :success

  def access?(file_number)
    !current_user_is_vso_employee? || BGSService.new.can_access?(file_number)
  end

  def error_status_or_search_results
    return { status: status } unless success

    search_results
  end

  def search_results
    @search_results ||= {
      search_results: {
        appeals: json_appeals(appeals),
        claim_reviews: claim_reviews.map(&:search_table_ui_hash)
      }
    }
  end

  def vso_employee_has_access
    return unless current_user_is_vso_employee?

    errors.add(:workflow, prohibited_error) if veterans_user_can_access.empty? && veterans.any?
    @status = :forbidden
  end

  def prohibited_error
    {
      "title": "Access to Veteran file prohibited",
      "detail": "You do not have access to this claims file number"
    }
  end
end
