require 'rails_helper'

RSpec.describe CorrespondenceMailTask, type: :model do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers
  include CorrespondenceTaskActionsHelpers
  # let(:correspondence) { create(:correspondence) }
  # let(:root_task) { correspondence.root_task }
  # let(:mail_team) { InboundOpsTeam.singleton }
  # let(:litigation_support_org) { LitigationSupport.singleton }
  # let(:mail_team_user) { create(:user) }


  # # let(:lit_support_team) { LitigationSupport.singleton }
  # let(:random_user) { User.authenticate!(roles: []) }
  # let!(:litigation_user) do
  #   LitigationSupport.singleton.add_user(random_user)
  # end
  let!(:organizations) do
    organizations_array_list.map { |name| create(:organization, name: name) }
  end

  let(:privacy_user) { create(:user, css_id: "PRIVACY_TEAM_USER", full_name: "Leighton PrivacyAndFOIAUser Naumov") }
  let(:current_user) { create(:user) }
  let(:cavc_user) { create(:user, css_id: "CAVC_LIT_SUPPORT_ADMIN", full_name: "CAVCLitSupportAdmin") }
  let(:liti_user) { create(:user, css_id: "LITIGATION_SUPPORT_ADMIN", full_name: "LITIGATIONSUPPORT") }
  let(:colocated_user) { create(:user, css_id: "COLOCATED_ADMIN", full_name: "ColocatedAdmin") }
  let(:hearings_user) { create(:user, css_id: "HEARINGS_ADMIN", full_name: "HearingsAdmin") }
  let(:user_team) { InboundOpsTeam.singleton }
  let(:privacy_team) { PrivacyTeam.singleton }
  let(:cavc_team) { CavcLitigationSupport.singleton }
  let(:liti_team) { LitigationSupport.singleton }
  let(:colocated_team) { Colocated.singleton }
  let(:hearings_team) { HearingAdmin.singleton }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let!(:correspondence) { create(:correspondence, :completed, veteran: veteran) }


  context "testing tasks actions" do
    CorrespondenceTaskActionsHelpers::TASKS.each do |task_action|
      context "for #{task_action[:name]} tasks" do
        before do
          send("correspondence_spec_#{task_action[:access_type]}")
          FeatureToggle.enable!(:correspondence_queue)
          @correspondence = create(
            :correspondence,
            :completed,
            veteran: veteran,
            va_date_of_receipt: Time.zone.now,
            nod: false,
            notes: "Notes for #{task_action[:name]}"
          )
        end

        before :each do
          correspondence =  @correspondence
          task_class = task_action[:class]
          assigned_to_type = task_action[:assigned_to_type]
          assigned_to = send(task_action[:assigned_to])
          instructions = "#{task_action[:name]} Instructions"

            @task = task_class.create!(
            parent: correspondence.tasks[0],
            appeal: correspondence,
            appeal_type: "Correspondence",
            status: "assigned",
            assigned_to_type: assigned_to_type,
            assigned_to: assigned_to,
            instructions: [instructions],
            assigned_at: Time.current
            )
        end

    describe ".available_actions" do
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
          Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
          Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h
        ]
      end

        it "avalible actions show to the assigned user" do
          let(:current_user) { liti_user }
          expect(@task.available_actions(current_user)).to eq(expected_actions)
        end

      end
    end
  end

end






  # let(:user_array) do
  #   [
  #     { class: CavcCorrespondenceCorrespondenceTask, assigned_to: CavcLitigationSupport.singleton },
  #     { class: CongressionalInterestCorrespondenceTask, assigned_to: LitigationSupport.singleton },
  #     { class: DeathCertificateCorrespondenceTask, assigned_to: InboundOpsTeam.singleton },
  #     { class: FoiaRequestCorrespondenceTask, assigned_to: PrivacyTeam.singleton },
  #     { class: OtherMotionCorrespondenceTask, assigned_to: LitigationSupport.singleton },
  #     { class: PowerOfAttorneyRelatedCorrespondenceTask, assigned_to: HearingAdmin.singleton },
  #     { class: PrivacyActRequestCorrespondenceTask, assigned_to: InboundOpsTeam.singleton },
  #     { class: PrivacyComplaintCorrespondenceTask, assigned_to: PrivacyTeam.singleton },
  #     { class: StatusInquiryCorrespondenceTask, assigned_to: LitigationSupport.singleton }
  #   ]
  # end

  # describe ".available_actions" do
  #   let(:mail_task) { described_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: mail_team) }
  #   subject { mail_task.available_actions(current_user) }

  #   context "when the current user is a member of the litigation support team" do
  #     let(:current_user) { litigation_user }

  #     # before { expect(litigation_support_org.user_has_access?(current_user)).to eq(true) }

  #     let(:expected_actions) do
  #       [
  #         Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
  #         Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
  #         Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
  #         Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
  #       ]
  #     end

  #     it "returns the available actions for the litigation user" do
  #       expect(subject).to eq(expected_actions)
  #     end
  #   end

  #   context "when the current user is a member of the mail task team and does not have litigation support access" do
  #     let(:current_user) { mail_team_user }

  #     before { expect(litigation_support_org.user_has_access?(current_user)).to eq(false) }

  #     it "returns an empty array for mail task users without litigation access" do
  #       expect(subject).to eq([])
  #     end
  #   end
  # end

  # describe ".accessibility_for_users" do
  #   context "mail task actions available for user" do
  #     let(:expected_actions) do
  #       [
  #         Constants.TASK_ACTIONS.CANCEL_CORRESPONDENCE_TASK.to_h,
  #         Constants.TASK_ACTIONS.COMPLETE_CORRESPONDENCE_TASK.to_h,
  #         Constants.TASK_ACTIONS.ASSIGN_CORR_TASK_TO_TEAM.to_h,
  #         Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h
  #       ]
  #     end

  #     it "allows the assigned user to access task actions and prevents unassigned users" do
  #       user_array.each do |user|
  #         allow(litigation_user).to receive(:organization).and_return(user[:assigned_to])

  #         user[:assigned_to].add_user(litigation_user)
  #         task = user[:class].create!(appeal: root_task.appeal, parent: root_task, assigned_to: user[:assigned_to])
  #         expect(task.available_actions(litigation_user)).to eq(expected_actions)
  #         expect(task.available_actions(mail_team_user)).to be_empty
  #         OrganizationsUser.remove_user_from_organization(litigation_user, user[:assigned_to])
  #       end
  #     end
  #   end
  # end
end
