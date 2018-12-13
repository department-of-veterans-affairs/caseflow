require "rails_helper"

describe RequestIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:description) { nil }
  let(:nonrating_decision_issue) do
    random_date = 2.days.ago
    create(:decision_issue,
           disposition: "test disposition",
           description: description,
           request_issues: [create(:request_issue,
                                   issue_category: "test category",
                                   decision_date: random_date,
                                   description: "request issue description")])
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

  it "finds the issue category" do
    expect(nonrating_decision_issue.issue_category).to eq("test category")
  end

  context "#formatted_description" do
    let(:rating_decision_issue) do
      create(:decision_issue,
             description: description,
             decision_text: "decision text",
             request_issues: [create(:request_issue,
                                     notes: "a note")])
    end

    context "without a description" do
      it "displays a formatted description" do
        expect(nonrating_decision_issue.formatted_description)
          .to eq("test disposition: test category - request issue description")
        expect(rating_decision_issue.formatted_description).to eq("decision text. Notes: a note")
      end
    end

    context "with a description" do
      let(:description) { "a description" }

      it "displays the description" do
        expect(nonrating_decision_issue.formatted_description).to eq(description)
        expect(rating_decision_issue.formatted_description).to eq(description)
      end
    end
  end
end
