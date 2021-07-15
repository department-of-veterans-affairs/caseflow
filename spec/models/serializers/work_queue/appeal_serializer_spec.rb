# frozen_string_literal: true

describe WorkQueue::AppealSerializer, :all_dbs do
  context "when an appeal has a decision issue with a decision date in the future" do
    let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
    let(:user) { create(:user, :vso_role) }
    subject { described_class.new(appeal, params: { user: user }) }

    context "when a VSO user views an appeal" do
      context "when the restrict_poa_visibility feature toggle is on" do
        before { FeatureToggle.enable!(:restrict_poa_visibility) }
        after { FeatureToggle.disable!(:restrict_poa_visibility) }
        describe "decision_issues" do
          it "does not display decision issues with a decision date in the future" do
            expect(subject.serializable_hash[:data][:attributes][:decision_issues]).to be_empty
          end
        end
      end

      context "when the restrict_poa_visibility feature toggle is off" do
        before do
          FeatureToggle.disable!(:restrict_poa_visibility)
          # The below setup catches an error where using the current_user method in AppealSerializer broke prod.
          # Previous tests did not catch this error because StubbableUser returned nil for current_user, even though
          # that method is not accessible in AppealSerializer
          allow(User).to receive(:current_user).and_throw("Error!")
        end
        after { FeatureToggle.enable!(:restrict_poa_visibility) }

        describe "decision_issues" do
          it "does display decision issues with a decision date in the future" do
            expect(subject.serializable_hash[:data][:attributes][:decision_issues].count).to eq(1)
          end

          it "accesses user information without breaking on the user passed into the policy" do
            expect { subject.serializable_hash[:data][:attributes][:decision_issues] }.not_to raise_error
          end
        end
      end
    end
  end
end
