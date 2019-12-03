# frozen_string_literal: true

class Api::V2::Appeals
  def initialize(veteran_file_number:, vbms_id:)
    @veteran_file_number = veteran_file_number
    @vbms_id = vbms_id
  end

  def to_hash
    all_reviews_and_appeals
  end

  private

  attr_reader :veteran_file_number, :vbms_id

  def legacy_appeals
    # Appeals API is currently limited to VBA appeals
    @legacy_appeals ||= AppealHistory.for_api(vbms_id: vbms_id).select do |series|
      series.aoj == :vba
    end
  end

  def hlrs
    @hlrs ||= HigherLevelReview.where(veteran_file_number: veteran_file_number).select { |hlr| hlr.request_issues.any? }
  end

  def supplemental_claims
    # Filter out remanded SC because status and information of those are display through
    # the original HLR or Appeal
    @supplemental_claims ||= SupplementalClaim.where(veteran_file_number: veteran_file_number)
      .where(decision_review_remanded: nil)
      .select { |sc| sc.request_issues.any? }
  end

  def appeals
    @appeals ||= Appeal.where(veteran_file_number: veteran_file_number).select { |appeal| appeal.request_issues.any? }
  end

  def all_reviews_and_appeals
    hlr_json = ::V2::HLRStatusSerializer.new(hlrs, is_collection: true).serializable_hash
    sc_json = ::V2::SCStatusSerializer.new(supplemental_claims, is_collection: true).serializable_hash
    appeal_json = ::V2::AppealStatusSerializer.new(
      appeals.map(&:decorated_with_status), is_collection: true
    ).serializable_hash
    legacy_appeal_json = ::V2::LegacyAppealStatusSerializer.new(legacy_appeals, is_collection: true).serializable_hash

    { data: hlr_json[:data] + sc_json[:data] + appeal_json[:data] + legacy_appeal_json[:data] }
  end
end
