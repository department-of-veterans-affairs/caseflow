# frozen_string_literal: true

class Api::V3::External::VeteranSerializer
  include FastJsonapi::ObjectSerializer
  attribute :veteran_file_number, &:file_number

  attribute :decision_reviews do |veteran|
    Appeal.where(veteran_file_number: veteran.file_number).map { |appeal| ::Api::V3::External::AppealSerializer.new(appeal).serialized_json }
    HigherLevelReview.where(benefit_type: %w[compensation pension fiduciary],
                            veteran_file_number: veteran.file_number).map { |hlr| ::Api::V3::External::HigherLevelReviewSerializer.new(hlr).serialized_json }
    SupplementalClaim.where(benefit_type: %w[compensation pension fiduciary],
                            veteran_file_number: veteran.file_number).map { |supp_claim| ::Api::V3::External::SupplementalClaimSerializer.new(supp_claim).serialized_json }
  end
end
