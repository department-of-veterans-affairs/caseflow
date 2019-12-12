# frozen_string_literal: true

# ephemeral class used for caching Rating Issues for client,
# and for creating DecisionIssues when a Rating Issue has contention_reference_ids

class RatingIssue
  include ActiveModel::Model

  attr_accessor :reference_id, :decision_text, :profile_date, :associated_end_products,
                :promulgation_date, :participant_id, :rba_contentions_data, :diagnostic_code,
                :benefit_type

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
        diagnostic_code: bgs_data[:dgnstc_tc],
        benefit_type: rating.pension? ? :pension : :compensation
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
        diagnostic_code: serialized_hash[:diagnostic_code],
        benefit_type: serialized_hash[:benefit_type]
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
