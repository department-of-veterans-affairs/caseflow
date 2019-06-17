# frozen_string_literal: true

class CaseSearchResultsBase
  include ActiveModel::Validations
  include ValidateVsoEmployeeCanAccessFileNumber

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

  def error_status_or_search_results
    return { status: status } unless success

    search_results
  end

  def search_results
    @search_results ||= {
      search_results: {
        appeals: json_appeals(appeals),
        claim_reviews: claim_reviews
      }
    }
  end
end
