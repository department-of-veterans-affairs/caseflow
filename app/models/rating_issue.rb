# ephemeral class used for caching Rating Issues for client,
# and for creating DecisionIssues when a Rating Issue has contention_reference_ids

class RatingIssue
  include ActiveModel::Model

  attr_accessor :reference_id, :decision_text, :profile_date, :associated_end_products,
                :promulgation_date, :participant_id, :rba_contentions_data, :disability_code

  class << self
    def from_bgs_hash(rating, bgs_data)
      new(
        reference_id: bgs_data[:rba_issue_id],
        rba_contentions_data: ensure_array_of_hashes(bgs_data.dig(:rba_issue_contentions)),
        profile_date: rating.profile_date,
        decision_text: bgs_data[:decn_txt],
        associated_end_products: rating.associated_end_products,
        promulgation_date: rating.promulgation_date,
        participant_id: rating.participant_id,
        disability_code: bgs_data[:dgnstc_tc]
      )
    end

    def deserialize(serialized_hash)
      new(
        participant_id: serialized_hash[:participant_id],
        reference_id: serialized_hash[:reference_id],
        decision_text: serialized_hash[:decision_text],
        associated_end_products: deserialize_end_products(serialized_hash),
        promulgation_date: serialized_hash[:promulgation_date],
        profile_date: serialized_hash[:profile_date],
        rba_contentions_data: serialized_hash[:rba_contentions_data],
        disability_code: serialized_hash[:disability_code]
      )
    end

    private

    def ensure_array_of_hashes(array_or_hash_or_nil)
      [array_or_hash_or_nil || {}].flatten
    end

    def deserialize_end_products(serialized_hash)
      return [] unless serialized_hash[:associated_end_products]

      serialized_hash[:associated_end_products].map do |end_product_hash|
        EndProduct.deserialize(end_product_hash)
      end
    end
  end

  def ui_hash
    serialize
  end

  # If you change this method, you will need to clear cache in prod for your changes to
  # take effect immediately. See DecisionReview#cached_serialized_ratings
  def serialize
    {
      participant_id: participant_id,
      reference_id: reference_id,
      decision_text: decision_text,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      ramp_claim_id: ramp_claim_id,
      title_of_active_review: title_of_active_review,
      rba_contentions_data: rba_contentions_data,
      associated_end_products: associated_end_products.map(&:serialize),
      disability_code: disability_code
    }
  end

  def title_of_active_review
    return unless reference_id

    request_issue = RequestIssue.find_active_by_contested_rating_issue_reference_id(reference_id)

    request_issue&.review_title
  end

  def decision_issue
    @decision_issue ||= DecisionIssue.find_by(participant_id: participant_id, rating_issue_reference_id: reference_id)
  end

  def benefit_type
    # TODO: https://github.com/department-of-veterans-affairs/caseflow/issues/8619
    # figure this out from VBMS response attributes. Could also be "pension"
    "compensation"
  end

  def ramp_claim_id
    associated_ramp_ep&.claim_id
  end

  def contention_reference_ids
    return [] unless rba_contentions_data

    @contention_reference_ids ||= calculate_contention_reference_ids
  end

  def source_request_issues
    return [] if contention_reference_ids.empty?

    @source_request_issues ||= calculate_source_request_issues
  end

  # tells whether a the rating issue was made as a decision in response to a contention
  def decides_contention?(contention_reference_id:)
    contention_reference_ids.any? { |reference_id| reference_id.to_s == contention_reference_id.to_s }
  end

  private

  def calculate_source_request_issues
    result = contention_reference_ids.map do |contention_reference_id|
      RequestIssue.find_by(contention_reference_id: contention_reference_id)
    end

    result.compact
  end

  def calculate_contention_reference_ids
    result = rba_contentions_data.map do |contention_data|
      contention_data.dig(:cntntn_id)
    end

    result.compact
  end

  def associated_ramp_ep
    @associated_ramp_ep ||= associated_end_products.find(&:ramp?)
  end
end
