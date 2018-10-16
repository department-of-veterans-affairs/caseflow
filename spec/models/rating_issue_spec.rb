require "rails_helper"

describe RatingIssue do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".from_bgs_hash" do
    subject { RatingIssue.from_bgs_hash(bgs_record) }

    let(:bgs_record) do
      {
        rba_issue_id: "NBA",
        decn_txt: "This broadcast may not be reproduced"
      }
    end

    it { is_expected.to be_a(RatingIssue) }

    it do
      is_expected.to have_attributes(
        reference_id: "NBA",
        decision_text: "This broadcast may not be reproduced"
      )
    end
  end

  context "#in_active_review" do
    let(:reference_id) { "abc123" }
    let(:review_request_type) { "SupplementalClaim" }

    let!(:request_issue) do
      create(:request_issue, rating_issue_reference_id: reference_id, review_request_type: review_request_type)
    end

    it "returns true if a RequestIssue already exists with the same reference_id" do
      rating_issue = RatingIssue.new(reference_id: reference_id)

      expect(rating_issue.in_active_review).to eq("Supplemental Claim")
    end
  end

  context "#save_with_request_issue!" do
    let(:contention_ref_id) { 123 }

    let!(:request_issue) { create(:request_issue, contention_reference_id: contention_ref_id) }

    it "matches based on contention_reference_id" do
      rating_issue = RatingIssue.new(
        reference_id: "ref-id",
        profile_date: Time.zone.today,
        contention_reference_id: contention_ref_id
      )

      expect(rating_issue.id).to be_nil

      rating_issue.save_with_request_issue!

      expect(rating_issue.request_issue).to eq(request_issue)
      expect(rating_issue.id).to_not be_nil
    end
  end
end
