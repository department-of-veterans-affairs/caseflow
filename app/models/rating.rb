# frozen_string_literal: true

# A Rating can be a PromulgatedRating, RatingAtIssue, or CurrentRating.
# Please see the subclasses for more information.

class Rating
  include ActiveModel::Model

  ONE_YEAR_PLUS_DAYS = 372.days
  TWO_LIFETIMES = 250.years

  class NilRatingProfileListError < StandardError
    def ignorable?
      true
    end
  end

  class << self
    def fetch_all(participant_id)
      fetch_timely(participant_id: participant_id, from_date: (Time.zone.today - TWO_LIFETIMES))
    end

    def fetch_timely(participant_id:, from_date:)
      fetch_in_range(
        participant_id: participant_id,
        start_date: from_date - ONE_YEAR_PLUS_DAYS,
        end_date: Time.zone.today
      )
    end

    def fetch_in_range(*)
      fail Caseflow::Error::MustImplementInSubclass
    end

    def sorted_ratings_from_bgs_response(response:, start_date:)
      unsorted = ratings_from_bgs_response(response)
      unpromulgated = unsorted.select { |rating| rating.promulgation_date.nil? }
      sorted = unsorted.reject do |rating|
        rating.promulgation_date.nil? || rating.promulgation_date < start_date
      end.sort_by(&:promulgation_date).reverse

      unpromulgated + sorted
    end

    def fetch_promulgated(participant_id)
      fetch_all(participant_id).select { |rating| rating.promulgation_date.present? }
    end

    def from_bgs_hash(_data)
      fail Caseflow::Error::MustImplementInSubclass
    end
  end

  # WARNING: profile_date is a misnomer adopted from BGS terminology.
  # It is a datetime, not a date.
  attr_accessor :participant_id, :profile_date, :promulgation_date, :rating_profile

  def serialize
    Intake::RatingSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def issues
    issues = Array.wrap(rating_profile[:rating_issues] || rating_profile.dig(:rba_issue_list, :rba_issue))

    issues.map do |issue|
      most_recent_disability_hash_for_issue = map_of_dis_sn_to_most_recent_disability_hash[issue[:dis_sn]]
      most_recent_evaluation_for_issue = most_recent_disability_hash_for_issue&.most_recent_evaluation
      special_issues = most_recent_disability_hash_for_issue&.special_issues

      if most_recent_evaluation_for_issue
        issue[:dgnstc_tc] = most_recent_evaluation_for_issue[:dgnstc_tc]
        issue[:prcnt_no] = most_recent_evaluation_for_issue[:prcnt_no]
      end
      issue[:special_issues] = special_issues if special_issues
      RatingIssue.from_bgs_hash(self, issue)
    end
  end

  def decisions
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])

    disability_data = Array.wrap(rating_profile[:disabilities] || rating_profile.dig(:disability_list, :disability))

    disability_data.map do |disability|
      RatingDecision.from_bgs_disability(self, disability)
    end
  end

  def associated_end_products
    associated_claims_data.map do |claim_data|
      EndProduct.new(
        claim_id: claim_data[:clm_id],
        claim_type_code: claim_data[:bnft_clm_tc]
      )
    end
  end

  def mst_from_contentions_for_rating?
    get_contentions_with_claim_ids.each do |contention|
      if mst_contention_status?(contention)
        return true
      else
        next
      end
    end
    false
  end

  def pact_from_contentions_for_rating?
    get_contentions_with_claim_ids.each do |contention|
      if pact_contention_status?(contention)
        return true
      else
        next
      end
    end
    false
  end

  def pension?
    associated_claims_data.any? { |ac| ac[:bnft_clm_tc].match(/PMC$/) }
  end

  private

  def ratings_from_bgs_response(_response)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def associated_claims_data
    associated_claims = rating_profile[:associated_claims] || rating_profile.dig(:rba_claim_list, :rba_claim)

    Array.wrap(associated_claims)
  end

  def map_of_dis_sn_to_most_recent_disability_hash
    @map_of_dis_sn_to_most_recent_disability_hash ||= RatingProfileDisabilities.new(
      Array.wrap(rating_profile[:disabilities] || rating_profile.dig(:disability_list, :disability))
    ).most_recent
  end

  def get_associated_claim_ids
    associated_claims_data.any? { |ac| ac.pluck(:clm_id) }
  end

  def get_contentions_with_claim_ids
    contetions_for_rating = []
    get_associated_claim_ids.each do |claim_id|
      # call BGS service with BGS service
      contetions_for_rating << BGS.new.find_contentions_by_claim_id(claim_id)
    end
    contentions_for_rating.flatten
  end

  def mst_contention_status?(bgs_contention)
    return false if bgs_contention.nil?
    if bgs_contention.special_issues.is_a?(Hash)
      return bgs_contention.special_issues[:spis_tc] == 'MST' if bgs_contention&.special_issues
    elsif bgs_contention.special_issues.is_a?(Array)
      bgs_contention.special_issues.each do |issue|
        return true if issue[:spis_tc] == 'MST'
      end
    end
    false
  end

  def pact_contention_status?
    return false if bgs_contention.nil?
    if bgs_contention.special_issues.is_a?(Hash)
      return ['PACT', 'PACTDICRE'].include?(bgs_contention.special_issues[:spis_tc]) if bgs_contention&.special_issues
    elsif bgs_contention.special_issues.is_a?(Array)
      bgs_contention.special_issues.each do |issue|
        return true if ['PACT', 'PACTDICRE'].include?(issue[:spis_tc])
      end
    end
    false
  end
end
