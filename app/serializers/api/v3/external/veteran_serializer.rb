# frozen_string_literal: true

class Api::V3::External::VeteranSerializer
  include FastJsonapi::ObjectSerializer
  attribute :veteran_file_number, &:file_number

  attribute :decision_reviews do |veteran|
    {
      "appeals":
        Appeal.where(veteran_file_number: veteran.file_number).map do |appeal|
          ::Api::V3::External::AppealSerializer.new(appeal)
        end,
      "higher_level_reviews":
        HigherLevelReview.where(benefit_type: %w[compensation pension fiduciary],
                                veteran_file_number: veteran.file_number).map do |hlr|
          ::Api::V3::External::HigherLevelReviewSerializer.new(hlr)
        end,
      "supplemental_claims":
        SupplementalClaim.where(benefit_type: %w[compensation pension fiduciary],
                                veteran_file_number: veteran.file_number).map do |supp_claim|
          ::Api::V3::External::SupplementalClaimSerializer.new(supp_claim)
        end
    }
  end
end
