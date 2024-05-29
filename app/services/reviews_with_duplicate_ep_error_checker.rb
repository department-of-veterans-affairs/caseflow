# frozen_string_literal: true

class ReviewsWithDuplicateEpErrorChecker < DataIntegrityChecker
  def call
    higher_level_review_ids = problem_higher_level_reviews.map(&:id)
    supplemental_claim_ids = problem_supplemental_claims.map(&:id)
    build_report(higher_level_review_ids, supplemental_claim_ids)
  end

  private

  ERROR_SELECTOR = "establishment_error ILIKE '%duplicateep%'"
  REFERENCE_LINK = "https://github.com/department-of-veterans-affairs/caseflow/issues/11081#issue-455423675"

  def problem_higher_level_reviews
    problem_reviews(reviews: HigherLevelReview.where(ERROR_SELECTOR), type: "030")
  end

  def problem_supplemental_claims
    problem_reviews(reviews: SupplementalClaim.where(ERROR_SELECTOR), type: "040")
  end

  def problem_reviews(reviews:, type:)
    reviews.select do |review|
      review.veteran.end_products.select do |ep|
        ep.claim_type_code.include?(type) &&
          %w[CAN CLR].include?(ep.status_type_code) &&
          ep.recent?
      end.empty?
    end
  end

  def build_report(higher_level_review_ids, supplemental_claim_ids)
    return if higher_level_review_ids.empty? && supplemental_claim_ids.empty?

    hlr_count = higher_level_review_ids.count
    hlr_ids = higher_level_review_ids.sort
    sc_count = supplemental_claim_ids.count
    sc_ids = supplemental_claim_ids.sort

    if hlr_count.positive?
      add_to_report "Found #{hlr_count} #{'HigherLevelReview'.pluralize(hlr_count)} with " \
        "DuplicateEP #{'error'.pluralize(hlr_count)}."
      add_to_report "`HigherLevelReview.where(id: #{hlr_ids})`"
    end

    if sc_count.positive?
      add_to_report "Found #{sc_count} #{'SupplementalClaim'.pluralize(sc_count)} with " \
        "DuplicateEP #{'error'.pluralize(sc_count)}."
      add_to_report "`SupplementalClaim.where(id: #{sc_ids})`"
    end

    add_to_report "The #{'review'.pluralize(sc_count + hlr_count)} may not progress without manual resolution."
    add_to_report "See: #{REFERENCE_LINK}"
  end
end
