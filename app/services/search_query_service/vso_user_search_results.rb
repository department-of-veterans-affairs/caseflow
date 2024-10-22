# frozen_string_literal: true

class SearchQueryService::VsoUserSearchResults
  def initialize(search_results:, user:)
    @user = user
    @search_results = search_results

    filter_restricted_results!
  end

  def call
    established_results.select do |result|
      if result.type == :appeal
        result.appeal.claimants.any? do |claimant|
          vso_participant_ids.include?(poas.dig(claimant.participant_id, :participant_id))
        end
      else
        vso_participant_ids.include?(poas.dig(result.appeal.veteran.participant_id, :participant_id))
      end
    end
  end

  private

  attr_reader :search_results, :user

  RESTRICTED_STATUSES =
    [
      :distributed_to_judge,
      :ready_for_signature,
      :on_hold,
      :misc,
      :unknown,
      :assigned_to_attorney
    ].freeze

  def filter_restricted_results!
    search_results.map do |result|
      result.filter_restricted_info!(RESTRICTED_STATUSES)
    end
  end

  def vso_participant_ids
    @vso_participant_ids ||= user.vsos_user_represents.map { |poa| poa[:participant_id] }
  end

  def established_results
    @established_results ||= search_results.select do |result|
      result.type == :legacy_appeal || result.appeal.established_at.present?
    end
  end

  def claimant_participant_ids
    @claimant_participant_ids ||= established_results.flat_map do |result|
      result.appeal.claimant_participant_ids
    end.uniq
  end

  def poas
    Rails.logger.info "BGS Called `fetch_poas_by_participant_ids` with \"#{claimant_participant_ids.join('"')}\""

    @poas ||= bgs.fetch_poas_by_participant_ids(claimant_participant_ids)
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
