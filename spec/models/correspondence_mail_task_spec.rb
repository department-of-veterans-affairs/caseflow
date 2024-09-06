require 'rails_helper'

RSpec.describe CorrespondenceMailTask, type: :model do
  let(:correspondence) { create(:correspondence) }
  let(:root_task) { correspondence.root_task }
  let(:mail_team) { create(:mail_team) }
  let(:litigation_user) { create(:user, roles: ['Litigation Support']) }
  let(:mail_task_user) { create(:user, roles: ['Mail Task']) }

  let(:user_array) do
    [
      { class: CavcCorrespondenceCorrespondenceTask, assigned_to: CavcLitigationSupport.singleton },
      { class: CongressionalInterestCorrespondenceTask, assigned_to: LitigationSupport.singleton },
      { class: DeathCertificateCorrespondenceTask, assigned_to: InboundOpsTeam.singleton },
      { class: FoiaRequestCorrespondenceTask, assigned_to: PrivacyTeam.singleton },
      { class: OtherMotionCorrespondenceTask, assigned_to: LitigationSupport.singleton },
      { class: PowerOfAttorneyRelatedCorrespondenceTask, assigned_to: HearingAdmin.singleton },
      { class: PrivacyActRequestCorrespondenceTask, assigned_to: InboundOpsTeam.singleton },
      { class: PrivacyComplaintCorrespondenceTask, assigned_to: PrivacyTeam.singleton },
      { class: StatusInquiryCorrespondenceTask, assigned_to: LitigationSupport.singleton }
    ]
  end

  describe ".available_actions" do
    let(:mail_task) { described_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: mail_team) }

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
    context "mail task actions available for user" do
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
          Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
          Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
        ]
      end

      it "allows the assigned user to access task actions and prevents unassigned users" do
        user_array.each do |user|
          allow_any_instance_of(User).to receive(:organization).and_return(user[:assigned_to])
          user[:assigned_to].add_user(litigation_user)

          task = user[:class].create!(appeal: root_task.appeal, parent: root_task, assigned_to: user[:assigned_to])

          expect(task.available_actions(litigation_user)).to eq(expected_actions)
          expect(task.available_actions(mail_task_user)).to be_empty

          OrganizationsUser.remove_user_from_organization(litigation_user, user[:assigned_to])
        end
      end
    end
  end
end
