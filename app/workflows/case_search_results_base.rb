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

  def search_call
    @success = valid?

    case_search_results if success

    FormResponse.new(
      success: success,
      errors: errors.messages[:workflow],
      extra: error_status_or_case_search_results
    )
  end

  def api_call
    @success = valid?

    api_search_results if success

    FormResponse.new(
      success: success,
      errors: errors.messages[:workflow],
      extra: error_status_or_api_search_results
    )
  end

  protected

  attr_reader :status, :user

  def search_page_json_appeals(appeals)
    ama_appeals, legacy_appeals = appeals.partition { |appeal| appeal.is_a?(Appeal) }

    ama_hash = WorkQueue::AppealSearchSerializer.new(
      ama_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    legacy_hash = WorkQueue::LegacyAppealSearchSerializer.new(
      legacy_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    ama_hash[:data].concat(legacy_hash[:data])
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

  def current_user_is_vso_employee?
    user.vso_employee?
  end

  def claim_reviews
    ClaimReview.find_all_visible_by_file_number(veterans_user_can_access.map(&:file_number))
  end

  # Child classes will likely override this
  def veterans
    []
  end

  def appeals
    []
  end

  # Users may also view appeals with appellants whom they represent.
  # We use this to add these appeals back into results when the user is not on the veteran's poa.
  def additional_appeals_user_can_access
    appeals.map(&:appeal).filter do |appeal|
      appeal.veteran_is_not_claimant &&
        user.organizations.any? do |uo|
          appeal.representatives.include?(uo)
        end
    end
  end

  def veterans_user_can_access
    @veterans_user_can_access ||= veterans.select { |veteran| access?(veteran.file_number) }
  end

  private

  attr_reader :success

  def access?(file_number)
    return true if !current_user_is_vso_employee?

    Rails.logger.info "BGS Called `can_access?` with \"#{file_number}\""

    bgs.can_access?(file_number)
  end

  def bgs
    @bgs ||= BGSService.new
  end

  def veterans_exist
    return unless veterans_user_can_access.empty?

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def error_status_or_search_results
    return { status: status } unless success

    search_results
  end

  def error_status_or_case_search_results
    return { status: status } unless success

    case_search_results
  end

  def error_status_or_api_search_results
    return { status: status } unless success

    api_search_results
  end

  def error_status_or_api_case_search_results
    return { status: status } unless success

    api_case_search_results
  end

  def api_search_results
    @api_search_results ||= {
      search_results: {
        appeals: json_appeals(appeal_finder_appeals),
        claim_reviews: claim_reviews.map(&:search_table_ui_hash)
      }
    }
  end

  def api_case_search_results
    @api_case_search_results ||= {
      case_search_results: {
        appeals: search_page_json_appeals(appeal_finder_appeals),
        claim_reviews: claim_reviews.map(&:search_table_ui_hash)
      }
    }
  end

  def search_results
    @search_results ||= {
      search_results: {
        appeals: appeals.map(&:api_response),
        claim_reviews: claim_reviews.map(&:search_table_ui_hash)
      }
    }
  end

  def case_search_results
    @case_search_results ||= {
      case_search_results: {
        appeals: appeals.map(&:api_response),
        claim_reviews: claim_reviews.map(&:search_table_ui_hash)
      }
    }
  end

  def vso_employee_has_access
    return unless current_user_is_vso_employee?

    errors.add(:workflow, prohibited_error) if
      veterans_user_can_access.empty? &&
      veterans.any? &&
      additional_appeals_user_can_access.empty?
    @status = :forbidden
  end

  def prohibited_error
    {
      "title": "Access to Veteran file prohibited",
      "detail": "You do not have access to this claims file number"
    }
  end
end
