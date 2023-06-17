# frozen_string_literal: true

# ephemeral class used for caching Rating Issues for client,
# and for creating DecisionIssues when a Rating Issue has contention_reference_ids

class RatingIssue
  include ActiveModel::Model
  CONTENTION_PACT_ISSUES = %w[PACT PACTDICRE].freeze

  attr_accessor(
    :associated_end_products,
    :benefit_type,
    :decision_text,
    :diagnostic_code,
    :participant_id,
    :percent_number,
    :profile_date,
    :promulgation_date,
    :rba_contentions_data,
    :reference_id,
    :subject_text,
    :special_issues
    # adding another field? *
  )

  # * RatingIssues get cached (DecisionReview#cached_serialized_ratings),
  # and are serialized and then deserialized during that process.
  # If you are adding another field to RatingIssue, you'll most likely
  # want to update the serializer as well:
  #   app/serializers/intake/rating_issue_serializer.rb
  # --If a field isn't in the serializer, it will be nil when using a
  # cached RatingIssue.
  #
  # Places you'll (probably) want to update when adding a new field:
  #  attr_accessor in RatingIssue (above)
  #  RatingIssue.from_bgs_hash
  #  RatingIssue.deserialize
  #  app/serializers/intake/rating_issue_serializer.rb (used in RatingIssue#serialize)

  class << self
    def from_bgs_hash(rating, bgs_data)
      new(
        associated_end_products: rating.associated_end_products,
        benefit_type: rating.pension? ? :pension : :compensation,
        decision_text: bgs_data[:decn_txt],
        diagnostic_code: bgs_data[:dgnstc_tc],
        participant_id: rating.participant_id,
        percent_number: bgs_data[:prcnt_no],
        profile_date: rating.profile_date,
        promulgation_date: rating.promulgation_date,
        rba_contentions_data: ensure_array_of_hashes(bgs_data.dig(:rba_issue_contentions)),
        reference_id: bgs_data[:rba_issue_id],
        subject_text: bgs_data[:subjct_txt],
        special_issues: bgs_data[:special_issues]
      )
    end

    def deserialize(serialized_hash)
      new(
        serialized_hash.slice(
          :benefit_type,
          :decision_text,
          :diagnostic_code,
          :participant_id,
          :percent_number,
          :profile_date,
          :promulgation_date,
          :rba_contentions_data,
          :reference_id,
          :subject_text
        ).merge(associated_end_products: deserialize_end_products(serialized_hash))
         .merge(special_issues: deserialize_special_issues(serialized_hash))
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

    def deserialize_special_issues(serialized_hash)
      data = []
      serialized_hash[:special_issues]&.each do |special_issue|
        data << { mst_available: true } if special_issue_has_mst?(special_issue)

        data << { pact_available: true } if special_issue_has_pact?(special_issue)
      end
      if serialized_hash[:rba_contentions_data]
        data << { mst_available: true } if mst_from_contentions_for_rating?(serialized_hash)

        data << { pact_available: true } if pact_from_contentions_for_rating?(serialized_hash)
      end
      data
    end

    def special_issue_has_mst?(special_issue)
      if special_issue[:spis_tn].casecmp("ptsd - personal trauma").zero?
        return ["sexual trauma/assault", "sexual Hhrassment"].include?(special_issue[:spis_basis_tn].downcase)
      end

      if special_issue[:spis_tn].casecmp("non-ptsd - personal trauma").zero?
        ["sexual assault trauma", "sexual harassment"].include?(special_issue[:spis_basis_tn].downcase)
      end
    end

    def special_issue_has_pact?(special_issue)
      if special_issue[:spis_tn].casecmp("gulf war presumptive 3.3201").zero?
        return special_issue[:spis_basis_tn].casecmp("particulate matter").zero?
      end

      [
        "agent orange - outside vietnam or unknown",
        "agent orange - vietnam",
        "amytrophic lateral sclerosis",
        "burn pit exposure",
        "environmental hazard in gulf war",
        "gulf war presumptive",
        "radiation"
      ].include?(special_issue[:spis_tn].downcase)
    end

    def mst_from_contentions_for_rating?(serialized_hash)
      contentions = participant_contentions(serialized_hash)
      return false if contentions.blank?

      contentions.any? { |contention| mst_contention_status?(contention) }
    end

    def pact_from_contentions_for_rating?(serialized_hash)
      contentions = participant_contentions(serialized_hash)
      return false if contentions.blank?

      contentions.any? { |contention| pact_contention_status?(contention) }
    end

    def participant_contentions(serialized_hash)
      contentions_data = []
      response = Rating.fetch_contentions_by_participant_id(serialized_hash[:participant_id])

      serialized_hash[:rba_contentions_data].each do |rba|
        response.each do |resp|
          contentions_data << resp[:contentions] if resp[:contentions][:cntntn_id] == rba[:cntntn_id]
        end
      end
      contentions_data.compact
    end

    def mst_contention_status?(bgs_contention)
      return false if bgs_contention.nil? || bgs_contention[:special_issues].blank?

      if bgs_contention[:special_issues].is_a?(Hash)
        bgs_contention[:special_issues][:spis_tc] == "MST"
      elsif bgs_contention[:special_issues].is_a?(Array)
        bgs_contention[:special_issues].any? { |issue| issue[:spis_tc] == "MST" }
      end
    end

    def pact_contention_status?(bgs_contention)
      return false if bgs_contention.nil? || bgs_contention[:special_issues].blank?

      if bgs_contention[:special_issues].is_a?(Hash)
        CONTENTION_PACT_ISSUES.include?(bgs_contention[:special_issues][:spis_tc])
      elsif bgs_contention[:special_issues].is_a?(Array)
        bgs_contention[:special_issues].any? { |issue| CONTENTION_PACT_ISSUES.include?(issue[:spis_tc]) }
      end
    end
  end

  def serialize
    Intake::RatingIssueSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def decision_issue
    @decision_issue ||= DecisionIssue.find_by(participant_id: participant_id, rating_issue_reference_id: reference_id)
  end

  def ramp_claim_id
    associated_ramp_ep&.claim_id
  end

  def contention_reference_ids
    return [] unless rba_contentions_data

    @contention_reference_ids ||= calculate_contention_reference_ids
  end

  # TODO: if request issues are found to be the source of a rating issue that with no matching decision issue,
  # that means we did not create a decision issue somewhere. This is a problem and we should probably throw an
  # error in this scenario. For now we will assume this does not happen.
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
