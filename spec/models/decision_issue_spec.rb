require "rails_helper"

describe DecisionIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:description) { nil }

  let(:decision_issue) do
    create(
      :decision_issue,
      disposition: "test disposition",
      decision_text: decision_text,
      description: description,
      request_issues: request_issues
    )
  end

  let(:request_issues) { [] }
  let(:decision_text) { "decision text" }

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
        nonrating_issue_description: "request issue description",
        description: "request issue description"
      )]
    end

    it "finds the issue category" do
      is_expected.to eq("test category")
    end
  end

  context "#formatted_description" do
    subject { decision_issue.formatted_description }

    context "when description not set" do
      context "when nonrating" do
        let(:request_issues) do
          [create(
            :request_issue,
            :nonrating,
            issue_category: "test category",
            nonrating_issue_description: "req issue description",
            description: "req issue description"
          )]
        end

        it { is_expected.to eq("test disposition: test category - req issue description") }
      end
    end

    context "when description set" do
      let(:description) { "a description" }

      it { is_expected.to eq(description) }
    end
  end
end
