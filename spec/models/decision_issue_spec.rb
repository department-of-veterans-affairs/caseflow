require "rails_helper"

describe DecisionIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:decision_issue) do
    create(
      :decision_issue,
      decision_review: decision_review,
      disposition: disposition,
      decision_text: decision_text,
      description: description,
      request_issues: request_issues,
      benefit_type: "compensation"
    )
  end

  let(:request_issues) { [] }
  let(:description) { "description" }
  let(:disposition) { "allowed" }
  let(:decision_text) { "decision text" }
  let(:decision_review) { create(:supplemental_claim) }

  context "#save" do
    subject { decision_issue.save }

    context "when description is not set" do
      let(:description) { nil }

      context "when decision text is set" do
        it "sets description" do
          subject
          expect(decision_issue).to have_attributes(description: "decision text")
        end
      end

      context "when decision text is not set" do
        let(:decision_text) { nil }
        let(:request_issues) { [create(:request_issue, :rating, contested_issue_description: "req desc")] }

        it "sets description" do
          subject

          expect(decision_issue).to have_attributes(description: "allowed: req desc")
        end
      end
    end

    context "when description is already set" do
      let(:description) { "this is my decision" }

      it "doesn't overwrite description" do
        subject
        expect(decision_issue).to have_attributes(description: "this is my decision")
      end
    end
  end

  context "#finalized?" do
    subject { decision_issue.finalized? }

    context "decision_review is Appeal" do
      let(:description) { "something" }
      let(:disposition) { "denied" }

      context "is not outcoded" do
        let(:decision_review) { create(:appeal, :with_tasks) }

        it { is_expected.to be_falsey }
      end

      context "is outcoded" do
        let(:decision_review) { create(:appeal, :outcoded) }

        it { is_expected.to be_truthy }
      end
    end

    context "decision_review is ClaimReview" do
      context "disposition is set" do
        let(:disposition) { "denied" }

        it { is_expected.to be_truthy }
      end

      context "disposition is not set" do
        let(:disposition) { nil }

        it { is_expected.to be_falsey }
      end
    end
  end

  context "#rating?" do
    subject { decision_issue.rating? }

    context "when there are no associated nonrating issues" do
      let(:request_issues) do
        [create(:request_issue, :rating)]
      end

      it { is_expected.to eq true }
    end

    context "when there is one associated nonrating issue" do
      let(:request_issues) do
        [create(:request_issue, :rating), create(:request_issue, :nonrating)]
      end

      it { is_expected.to eq false }
    end
  end

  context "#approx_decision_date" do
    subject { decision_issue.approx_decision_date }

    let(:profile_date) { nil }
    let(:end_product_last_action_date) { nil }

    let(:decision_issue) do
      build(:decision_issue, profile_date: profile_date, end_product_last_action_date: end_product_last_action_date)
    end

    context "when there is no profile date" do
      it "returns nil" do
        expect(subject).to be_nil
      end

      context "when there is an end_product_last_action_date" do
        let(:end_product_last_action_date) { 4.days.ago }

        it "returns the end_product_last_action_date" do
          expect(subject).to eq(4.days.ago.to_date)
        end
      end
    end

    context "when there is a profile date" do
      let(:profile_date) { 3.days.ago }
      let(:end_product_last_action_date) { 4.days.ago }

      it "returns the profile_date" do
        expect(subject).to eq(3.days.ago.to_date)
      end
    end
  end

  context "#issue_category" do
    subject { decision_issue.issue_category }

    let(:request_issues) do
      [create(
        :request_issue,
        issue_category: "test category",
        nonrating_issue_description: "request issue description"
      )]
    end

    it "finds the issue category" do
      is_expected.to eq("test category")
    end
  end

  context "#find_or_create_remand_supplemental_claim!" do
    subject { decision_issue.find_or_create_remand_supplemental_claim! }

    context "when supplemental claim already exists matching decision issue" do
      let!(:matching_supplemental_claim) do
        create(
          :supplemental_claim,
          veteran_file_number: decision_review.veteran_file_number,
          decision_review_remanded: decision_review,
          benefit_type: "compensation"
        )
      end

      it "does not create a new supplemental claim" do
        expect do
          expect(subject).to eq(matching_supplemental_claim)
        end.to_not change(SupplementalClaim, :count)
      end
    end

    context "when no supplemental claim matches decision issue" do
      let(:decision_review) { create(:appeal, number_of_claimants: 1) }

      # Test that this supplemental claim does not match
      let!(:another_supplemental_claim) do
        create(
          :supplemental_claim,
          veteran_file_number: decision_review.veteran_file_number,
          decision_review_remanded: decision_review,
          benefit_type: "insurance"
        )
      end

      it "creates a new supplemental claim" do
        expect(subject).to have_attributes(
          veteran_file_number: decision_review.veteran_file_number,
          decision_review_remanded: decision_review,
          benefit_type: "compensation"
        )

        expect(subject.claimants.count).to eq(1)
        expect(subject.claimants.first).to have_attributes(
          participant_id: decision_review.claimant_participant_id,
          payee_code: "00"
        )
      end
    end
  end
end
