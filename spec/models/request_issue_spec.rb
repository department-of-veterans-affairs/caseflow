require "rails_helper"

describe RequestIssue do
  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:veteran) { Generators::Veteran.build(file_number: "789987789") }

  let!(:rated_issue) do
    RequestIssue.create(
      review_request: review,
      rating_issue_reference_id: "abc123",
      rating_issue_profile_date: Time.zone.now,
      description: "a rated issue"
    )
  end

  let!(:non_rated_issue) do
    RequestIssue.create(
      review_request: review,
      description: "a non-rated issue description",
      issue_category: "a category",
      decision_date: 1.day.ago
    )
  end

  let!(:unidentified_issue) do
    RequestIssue.create(
      review_request: review,
      description: "an unidentified issue",
      is_unidentified: true
    )
  end

  context "finds issues" do
    it "filters by rated issues" do
      rated_issues = RequestIssue.rated
      expect(rated_issues.length).to eq(2)
      expect(rated_issues.find_by(id: rated_issue.id)).to_not be_nil
      expect(rated_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end

    it "filters by nonrated issues" do
      nonrated_issues = RequestIssue.nonrated
      expect(nonrated_issues.length).to eq(1)
      expect(nonrated_issues.find_by(id: non_rated_issue.id)).to_not be_nil
    end

    it "filters by unidentified issues" do
      unidentified_issues = RequestIssue.unidentified
      expect(unidentified_issues.length).to eq(1)
      expect(unidentified_issues.find_by(id: unidentified_issue.id)).to_not be_nil
    end
  end

  context "#contention_text" do
    subject { request_issue.contention_text }

    context "rated issue" do
      let(:request_issue) { rated_issue }
      it { is_expected.to eq(request_issue.description) }
    end

    context "non-rated issue" do
      let(:request_issue) { non_rated_issue }
      it { is_expected.to eq("a category - a non-rated issue description") }
    end

    context "unidentified issue" do
      let(:request_issue) { unidentified_issue }
      it { is_expected.to eq(RequestIssue::UNIDENTIFIED_ISSUE_MSG) }
    end
  end
end
