require 'rails_helper'

RSpec.describe CorrespondenceMailTask, type: :model do
  describe ".available_actions" do
    let(:root_task) { create(:root_task) }
    let(:mail_team) { create(:mail_team) }
    let(:litigation_user) { create(:user, roles: ['Litigation Support']) }
    let(:mail_task_user) { create(:user, roles: ['Mail Task']) }
    let(:mail_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: mail_team) }

    subject { mail_task.available_actions(current_user) }

    context "when the current user is a member of the litigation support team" do
      let(:current_user) { litigation_user }

      before { allow_any_instance_of(User).to receive(:litigation_support?).and_return(true) }

      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
          Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
          Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
        ]
      end

      it "returns the available actions for the litigation user" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when the current user is a member of the mail task team and does not have litigation support access" do
      let(:current_user) { mail_task_user }

      before { allow_any_instance_of(User).to receive(:litigation_support?).and_return(false) }

      it "returns an empty array for mail task users without litigation access" do
        expect(subject).to eq([])
      end
    end
  end

  describe ".accessibility_for_users" do
    let(:user_array) do
      [
        { class: CavcCorrespondenceCorrespondenceTask, assigned_to: CavcCorrespondenceTeam.singleton },
        { class: CongressionalInterestCorrespondenceTask, assigned_to: CongressionalInterestTeam.singleton },
        { class: DeathCertificateCorrespondenceTask, assigned_to: DeathCertificateTeam.singleton },
        { class: FoiaRequestCorrespondenceTask, assigned_to: FoiaRequestTeam.singleton },
        { class: OtherMotionCorrespondenceTask, assigned_to: PrivacyTeam.singleton },
        { class: PowerOfAttorneyRelatedCorrespondenceTask, assigned_to: PowerOfAttorneyRelatedTeam.singleton },
        { class: PrivacyActRequestCorrespondenceTask, assigned_to: PrivacyActRequestTeam.singleton },
        { class: PrivacyComplaintCorrespondenceTask, assigned_to: PrivacyComplaintTeam.singleton },
        { class: StatusInquiryCorrespondenceTask, assigned_to: StatusInquiryTeam.singleton }
      ]
    end

    user_array.each do |user|
      context "for #{user[:class]} assigned to #{user[:assigned_to]}" do
        let(:task) { user[:class].create!(appeal: root_task.appeal, parent: root_task, assigned_to: user[:assigned_to]) }
        let(:expected_actions) do
          [
            Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
            Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
            Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
            Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
          ]
        end

        before do
          allow_any_instance_of(User).to receive(:organization).and_return(user[:assigned_to])
          # Assign user to organization
          user[:assigned_to].add_user(litigation_user)
        end

        after do
          # Remove user from organization
          OrganizationsUser.remove_user_from_organization(litigation_user, user[:assigned_to])
        end

        it "allows the assigned user to access task actions" do
          expect(task.available_actions(litigation_user)).to eq(expected_actions)
        end

        it "does not allow unassigned users to access task actions" do
          expect(task.available_actions(mail_task_user)).to be_empty
        end
      end
    end
  end
end
