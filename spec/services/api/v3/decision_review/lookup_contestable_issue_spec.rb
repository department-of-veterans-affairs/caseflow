# frozen_string_literal: true

# require "support/intake_helpers"

describe Api::V3::DecisionReview::LookupContestableIssue, :all_dbs do
  include IntakeHelpers

  def lookup(rating_issue_id: nil, decision_issue_id: nil, rating_decision_issue_id: nil)
    Api::V3::DecisionReview::LookupContestableIssue.new(
      decision_review_class: decision_review_class,
      veteran: veteran,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      rating_issue_id: rating_issue_id,
      decision_issue_id: decision_issue_id,
      rating_decision_issue_id: rating_decision_issue_id
    )
  end

  let(:decision_review_class) { HigherLevelReview }
  let!(:veteran) do
    Generators::Veteran.build(
      file_number: file_number,
      first_name: first_name,
      last_name: last_name
    )
  end
  let(:file_number) { "55555555" }
  let(:first_name) { "Jane" }
  let(:last_name) { "Doe" }
  let(:receipt_date) { Time.zone.today - 6.days }
  let(:benefit_type) { "compensation" }

  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }
  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }

  describe "#valid?" do
    it "find a veteran's rating issues" do
      rating.issues.each do |issue|
        expect(lookup(rating_issue_id: issue.reference_id).valid?).to eq true
      end
    end
  end

  describe "#contestable_issue" do
    it "return the correct contestable issue" do
      ContestableIssueGenerator.new(
        decision_review_class.new(
          veteran_file_number: veteran.file_number,
          receipt_date: receipt_date,
          benefit_type: benefit_type
        )
      ).contestable_issues.each do |ci|
        expect(
          lookup(rating_issue_id: ci.rating_issue_reference_id).contestable_issue.as_json
        ).to eq ci.as_json
      end
    end
  end
end
