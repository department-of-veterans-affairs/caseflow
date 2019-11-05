# frozen_string_literal: true

context "api/docs/v3/decision_reviews.yaml" do
  let(:spec) do
    YAML.safe_load(File.read(File.join(Rails.root, "app/controllers/api/docs/v3/decision_reviews.yaml")))
  end

  it "exists and is valid yaml" do
    expect { spec }.not_to raise_error
  end

  it "has the correct benefit types" do
    benefit_types = Constants::ISSUE_CATEGORIES.keys
    benefit_types_in_spec = spec.dig(
      "components",
      "schemas",
      "BenefitType",
      "enum"
    )
    expect(benefit_types_in_spec).to match_array(benefit_types)
  end

  it "has the correct categories" do
    categories = Constants::ISSUE_CATEGORIES.values.flatten
    categories_in_spec = spec.dig(
      "components",
      "schemas",
      "NonratingIssueCategory",
      "enum"
    )
    expect(categories_in_spec).to match_array(categories)
  end

  it "provides examples of all of the possible error codes for HigherLevelReviews" do
    hlr_errors_in_spec = lambda do
      responses = spec.dig("paths", "/higher_level_reviews", "post", "responses")

      responses.reduce([]) do |acc, (status_code, status_body)|
        first_digit_of_status_code = status_code.to_s[0]
        next acc unless first_digit_of_status_code.match?(/4|5/) # skip if response isn't an error

        examples_hash = status_body.dig("content", "application/vnd.api+json", "examples")
        next acc unless examples_hash # skip if there are no examples

        acc + examples_hash.values.map do |value_hash|
          status, code, title = value_hash.dig("value", "errors", 0).values_at "status", "code", "title"
          [status.to_i, code.to_sym, title].to_s
        end
      end
    end.call

    hlr_errors = Api::V3::DecisionReview::IntakeError::KNOWN_ERRORS.map(&:to_s) +
                 [Api::V3::DecisionReview::IntakeError::UNKNOWN_ERROR.to_s]

    expect(hlr_errors_in_spec).to match_array(hlr_errors)
  end
end
