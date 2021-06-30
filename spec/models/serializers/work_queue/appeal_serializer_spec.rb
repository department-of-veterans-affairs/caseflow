# frozen_string_literal: true

describe WorkQueue::AppealSerializer, :all_dbs do
  let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
  subject { described_class.new(appeal, params: { user: user }) }

  context "when a VSO user views an appeal" do
    let(:user) { create(:user, :vso_role) }

    describe "decision_issues" do
      it "does not display decision issues with a decision date in the future" do
        expect(subject.serializable_hash[:data][:attributes][:decision_issues]).to match_array([])
      end
    end
  end
end
