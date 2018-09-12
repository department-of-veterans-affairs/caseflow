require "rails_helper"

describe RequestIssuesUpdate do
  before do
    FeatureToggle.enable!(:test_facols)

    review.create_issues!(existing_request_issues)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  # TODO: make it simpler to set up a completed claim review, with end product data
  # and contention data stubbed out properly
  let(:review) { create(:higher_level_review) }

  let!(:veteran) { Generators::Veteran.build(file_number: review.veteran_file_number) }

  let(:rated_end_product_establishment) do
    create(:end_product_establishment, source: review, code: "030HLRR")
  end

  let(:request_issue_contentions) do
    [
      Generators::Contention.build(
        claim_id: rated_end_product_establishment.reference_id,
        text: "Service connection for PTSD was granted at 10 percent"
      ),
      Generators::Contention.build(
        claim_id: rated_end_product_establishment.reference_id,
        text: "Service connection for left knee immobility was denied"
      )
    ]
  end

  let!(:existing_request_issues) do
    [
      RequestIssue.new(
        review_request: review,
        rating_issue_profile_date: Date.new(2017, 4, 5),
        rating_issue_reference_id: "issue1",
        contention_reference_id: request_issue_contentions[0].id,
        description: request_issue_contentions[0].text
      ),
      RequestIssue.new(
        review_request: review,
        rating_issue_profile_date: Date.new(2017, 4, 6),
        rating_issue_reference_id: "issue2",
        contention_reference_id: request_issue_contentions[1].id,
        description: request_issue_contentions[1].text
      )
    ]
  end

  let(:request_issues_update) do
    RequestIssuesUpdate.new(
      user: user,
      review: review,
      request_issues_data: request_issues_data
    )
  end

  let(:user) { create(:user) }

  let(:request_issues_data) { [] }

  let(:existing_request_issues_data) do
    existing_request_issues.map do |issue|
      {
        reference_id: issue.rating_issue_reference_id,
        # TODO: validate the string format this comes in
        profile_date: issue.rating_issue_profile_date,
        description: issue.description
      }
    end
  end

  let(:request_issues_data_with_new_issue) do
    existing_request_issues_data + [{
      reference_id: "issue3",
      profile_date: Date.new(2017, 4, 7),
      description: "Service connection for cancer was denied"
    }]
  end

  context "#created_issues" do
    subject { request_issues_update.created_issues }
    before { request_issues_update.perform! }

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { request_issues_data_with_new_issue }
      let(:new_request_issue) { RequestIssue.find_by(rating_issue_reference_id: "issue3") }

      it { is_expected.to contain_exactly(new_request_issue) }
    end

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it { is_expected.to eq([]) }
    end
  end

  context "#removed_issues" do
    subject { request_issues_update.removed_issues }
    before { request_issues_update.perform! }

    context "when new issues were removed as part of the update" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it { is_expected.to contain_exactly(existing_request_issues.last) }
    end

    context "when new issues were added as part of the update" do
      let(:request_issues_data) { request_issues_data_with_new_issue }

      it { is_expected.to eq([]) }
    end
  end

  context "#perform!" do
    subject { request_issues_update.perform! }

    context "when request issues are empty" do
      it "fails and adds to errors" do
        expect(subject).to be_falsey

        expect(request_issues_update.error_code).to eq(:request_issues_data_empty)
      end
    end

    context "when issues are exactly the same as existing issues" do
      let(:request_issues_data) { existing_request_issues_data }

      it "fails and adds to errors" do
        expect(subject).to be_falsey

        expect(request_issues_update.error_code).to eq(:no_changes)
      end
    end

    context "when issues contain new issues not in existing issues" do
      let(:request_issues_data) { request_issues_data_with_new_issue }

      it "saves update, adds issues, and calls create contentions" do
        allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original

        expect(subject).to be_truthy

        request_issues_update.reload

        expect(request_issues_update.before_request_issue_ids).to contain_exactly(
          *existing_request_issues.map(&:id)
        )

        expect(request_issues_update.after_request_issue_ids).to contain_exactly(
          *(existing_request_issues.map(&:id) + [review.request_issues.last.id])
        )

        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          hash_including(
            veteran_file_number: review.veteran_file_number,
            contention_descriptions: ["Service connection for cancer was denied"],
            special_issues: []
          )
        )

        expect(review.request_issues.count).to eq(3)

        created_issue = review.request_issues.find_by(rating_issue_reference_id: "issue3")
        expect(created_issue).to have_attributes(
          rating_issue_profile_date: Date.new(2017, 4, 7),
          description: "Service connection for cancer was denied"
        )
        expect(created_issue.contention_reference_id).to_not be_nil
      end
    end

    context "when issues contain a subset of existing issues" do
      let(:request_issues_data) { existing_request_issues_data[0...1] }

      it "saves update, removes issues, and calls remove contentions" do
        allow(Fakes::VBMSService).to receive(:remove_contention!).and_call_original

        expect(subject).to be_truthy

        request_issues_update.reload

        expect(request_issues_update.before_request_issue_ids).to contain_exactly(
          *existing_request_issues.map(&:id)
        )

        expect(request_issues_update.after_request_issue_ids).to contain_exactly(
          existing_request_issues.first.id
        )

        removed_issue = existing_request_issues.last.reload
        expect(removed_issue).to have_attributes(
          review_request: nil
        )
        expect(removed_issue.removed_at).to_not be_nil

        expect(Fakes::VBMSService).to have_received(:remove_contention!).with(request_issue_contentions.last)
      end
    end
  end
end
