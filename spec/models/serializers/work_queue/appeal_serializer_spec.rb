# frozen_string_literal: true

describe WorkQueue::AppealSerializer, :all_dbs do
  context "when an appeal has a decision issue with a decision date in the future" do
    let(:appeal) { create(:appeal, :decision_issue_with_future_date) }
    let(:user) { create(:user, :vso_role) }
    subject { described_class.new(appeal, params: { user: user }) }

    context "when a VSO user views an appeal" do
      context "when the restrict_poa_visibility feature toggle is on" do
        before { FeatureToggle.enable!(:restrict_poa_visibility, users: [user.css_id]) }
        after { FeatureToggle.disable!(:restrict_poa_visibility, users: [user.css_id]) }
        describe "decision_issues" do
          it "does not display decision issues with a decision date in the future" do
            expect(subject.serializable_hash[:data][:attributes][:decision_issues]).to be_empty
          end
        end
      end

      context "when the restrict_poa_visibility feature toggle is off" do
        before do
          FeatureToggle.disable!(:restrict_poa_visibility, users: [user.css_id])
          # The below setup catches an error where using the current_user method in AppealSerializer broke prod.
          # Previous tests did not catch this error because StubbableUser returned nil for current_user, even though
          # that method is not accessible in AppealSerializer
          allow(User).to receive(:current_user).and_throw("Error!")
        end
        after { FeatureToggle.enable!(:restrict_poa_visibility, users: [user.css_id]) }

        describe "decision_issues" do
          it "does display decision issues with a decision date in the future" do
            expect(subject.serializable_hash[:data][:attributes][:decision_issues].count).to eq(1)
          end

          it "accesses user information without breaking on the user passed into the policy" do
            expect { subject.serializable_hash[:data][:attributes][:decision_issues] }.not_to raise_error
          end
        end
      end

      context "when an appeal has an attorney claimant" do
        let(:participant_id) { "" }
        let(:claimant) { create(:claimant, :attorney, participant_id: participant_id) }
        let(:appeal) { create(:appeal, claimants: [claimant]) }
        subject { described_class.new(appeal, params: { user: user }) }
        it "returns nil for appellant_first_name" do
          # problem - no method of this in bgsattorney
          expect(subject.serializable_hash[:data][:attributes][:appellant_first_name]).to be_nil
        end
        it "returns nil for appellant_middle_name" do
          expect(subject.serializable_hash[:data][:attributes][:appellant_middle_name]).to be_nil
        end
        it "returns nil for appellant_last_name" do
          expect(subject.serializable_hash[:data][:attributes][:appellant_last_name]).to be_nil
        end
        it "returns nil for appellant_suffix" do
          expect(subject.serializable_hash[:data][:attributes][:appellant_suffix]).to be_nil
        end
      end
    end
  end

  context "when an appeal has a user that is part of the Supervisory Senior Council" do
    let!(:appeal) { create(:appeal) }
    let!(:current_user) { create(:user) }
    let!(:organization) { SupervisorySeniorCouncil.singleton }
    let!(:organization_user) { OrganizationsUser.make_user_admin(current_user, organization) }

    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:split_appeal_workflow)
    end

    subject { described_class.new(appeal, params: { user: current_user }) }

    it "can_edit_request_issues returns true" do
      expect(subject.serializable_hash[:data][:attributes][:can_edit_request_issues]).to eq(true)
    end
  end
end
