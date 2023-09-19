# frozen_string_literal: true

class Api::V3::External::VeteranSerializer
  include FastJsonapi::ObjectSerializer
  attribute :veteran_file_number, &:file_number

  attribute :decision_reviews do |veteran|
    [
      { "appeals": Appeal.where(veteran_file_number: veteran.file_number).map { |appeal| ::Api::V3::External::AppealSerializer.new(appeal) } },
      { "hlrs_not_processed_in_caseflow": HigherLevelReview.where(benefit_type: %w[compensation pension fiduciary],
                                                                  veteran_file_number: veteran.file_number).map { |hlr| ::Api::V3::External::HigherLevelReviewSerializer.new(hlr) } },
      { "scs_not_processed_in_caseflow": SupplementalClaim.where(benefit_type: %w[compensation pension fiduciary],
                                                                 veteran_file_number: veteran.file_number).map { |supp_claim| ::Api::V3::External::SupplementalClaimSerializer.new(supp_claim) } }
    ]
  end
end
