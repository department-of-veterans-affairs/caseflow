require "rails_helper"

describe RequestIssue do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  context "#approx_decision_date" do
    subject { decision_issue.approx_decision_date }

    let(:profile_date) { nil }
    let(:last_action_date) { nil }

    let(:decision_issue) do
      build(:decision_issue, profile_date: profile_date, last_action_date: last_action_date)
    end

    context "when there is no profile date" do
      it "returns nil" do
        expect(subject).to be_nil
      end

      context "when there is a last_action_date" do
        let(:last_action_date) { 4.days.ago }

        it "returns the last_action_date" do
          expect(subject).to eq(4.days.ago.to_date)
        end
      end
    end

    context "when there is a profile date" do
      let(:profile_date) { 3.days.ago }
      let(:last_action_date) { 4.days.ago }

      it "returns the profile_date" do
        expect(subject).to eq(3.days.ago.to_date)
      end
    end
  end
end
