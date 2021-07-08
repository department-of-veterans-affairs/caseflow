# frozen_string_literal: true

describe WorkQueue::AppealSerializer, :all_dbs do
  let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
  subject { described_class.new(appeal, params: { user: user }) }

  context "when a VSO user views an appeal" do
    let(:user) { create(:user, :vso_role) }

    context "when the restrict_poa_visibility feature toggle is on" do
      before { FeatureToggle.enable!(:restrict_poa_visibility) }
      describe "decision_issues" do
        it "does not display decision issues with a decision date in the future" do
          expect(subject.serializable_hash[:data][:attributes][:decision_issues]).to be_empty
        end
      end
    end

    context "when the restrict_poa_visibility feature toggle is off" do
      before { FeatureToggle.disable!(:restrict_poa_visibility) }
      describe "decision_issues" do
        it "does display decision issues with a decision date in the future" do
          expect(subject.serializable_hash[:data][:attributes][:decision_issues].count).to eq(1)
        end
      end
    end
  end
end
