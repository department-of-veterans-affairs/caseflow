# frozen_string_literal: true

require "appellant_notification.rb"
include IhpTaskPending

describe AppellantNotification do
  describe "class methods" do
    describe "self.handle_errors" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }

      context "if appeal is nil" do
        let(:empty_appeal) {}
        it "reports the error" do
          expect { AppellantNotification.handle_errors(empty_appeal) }.to raise_error(
            AppellantNotification::NoAppealError
          )
        end
      end

      context "with no claimant listed" do
        let(:appeal) { create(:appeal, number_of_claimants: 0) }
        it "returns error message" do
          expect(AppellantNotification.handle_errors(appeal)).to eq(
            AppellantNotification::NoClaimantError.new(appeal.id).message
          )
        end
      end

      context "with no participant_id listed" do
        let(:claimant) { create(:claimant, participant_id: "") }
        let(:appeal) { create(:appeal) }
        before do
          appeal.claimants = [claimant]
        end
        it "returns error message" do
          expect(AppellantNotification.handle_errors(appeal)).to eq(
            AppellantNotification::NoParticipantIdError.new(appeal.id).message
          )
        end
      end

      context "with no errors" do
        it "doesn't raise" do
          expect(AppellantNotification.handle_errors(appeal)).to eq "Success"
        end
      end
    end

    describe "self.create_payload" do
      let(:good_appeal) { create(:appeal, number_of_claimants: 1) }
      let(:bad_appeal) { create(:appeal) }
      let(:bad_claimant) { create(:claimant, participant_id: "") }
      let(:template_name) { "test" }

      context "creates a payload with no exceptions" do
        it "has a status value of success" do
          expect(
            AppellantNotification.create_payload(good_appeal, template_name)[:message_attributes][:status][:string_value]
          ).to eq "Success"
        end
      end

      context "creates a payload with errors" do
        before do
          bad_appeal.claimants = [bad_claimant]
        end
        it "does not have a success status" do
          expect(
            AppellantNotification.create_payload(bad_appeal, template_name)[:message_attributes][:status][:string_value]
          ).not_to eq "Success"
        end
      end
    end

    describe "self.notify_appellant" do
      let(:appeal) { create(:appeal, number_of_claimants: 1) }
      let(:template_name) { "test" }
      context "sends message to shoryuken" do
        it "sends the payload" do
          queue = double("queue")
          expect(queue).to receive(:send_message).with(AppellantNotification.create_payload(appeal, template_name))
          AppellantNotification.notify_appellant(appeal, template_name, queue)
        end
      end
    end
  end
end

describe AppellantNotification do
  describe AppealDocketed do
    describe "docket_appeal" do
      let(:appeal) { create(:appeal, :with_pre_docket_task) }
      let(:template_name) { "AppealDocketed" }
      let(:pre_docket_task) { PreDocketTask.find_by(appeal: appeal) }
      it "will notify appellant that Predocketed Appeal is docketed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        pre_docket_task.docket_appeal
      end
    end

    describe "create_tasks_on_intake_success!" do
      let(:appeal) { create(:appeal) }
      let(:template_name) { "AppealDocketed" }
      it "will notify appellant that appeal is docketed on successful intake" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        appeal.create_tasks_on_intake_success!
      end
    end
  end

  describe AppealDecisionMailed do
    describe "Legacy Appeal Decision Mailed" do
      let(:legacy_appeal) { create(:legacy_appeal, :with_root_task, vbms_id: 123_456) }
      let(:params) do
        {
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested) { "AppealDecisionMailedContested" }
      let(:non_contested) { "AppealDecisionMailedNonContested" }
      let(:dispatch) { LegacyAppealDispatch.new(appeal: legacy_appeal, params: params) }
      it "Will notify appellant that the legacy appeal decision has been mailed (Non Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(legacy_appeal, non_contested)
        dispatch.complete_root_task!
      end
      it "Will notify appellant that the legacy appeal decision has been mailed (Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(legacy_appeal, contested)
        allow(legacy_appeal).to receive(:contested_claim).and_return(true)
        legacy_appeal.contested_claim
        dispatch.complete_root_task!
      end
    end

    describe "AMA Appeal Decision Mailed" do
      let(:appeal) { create(:appeal, :with_assigned_bva_dispatch_task) }
      let(:contested_appeal) { create(:appeal, :with_assigned_bva_dispatch_task, :with_request_issues) }
      let(:params) do
        {
          appeal_id: appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested_params) do
        {
          appeal_id: contested_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested) { "AppealDecisionMailedContested" }
      let(:non_contested) { "AppealDecisionMailedNonContested" }
      let(:dispatch) { AmaAppealDispatch.new(appeal: appeal, params: params, user: User.find(appeal.tasks.find_by(assigned_to_type: "User").assigned_to_id)) }
      let(:contested_dispatch) { AmaAppealDispatch.new(appeal: contested_appeal, params: contested_params, user: User.find(contested_appeal.tasks.find_by(assigned_to_type: "User").assigned_to_id)) }
      it "Will notify appellant that the AMA appeal decision has been mailed (Non Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, non_contested)
        dispatch.complete_dispatch_root_task!
      end
      it "Will notify appellant that the AMA appeal decision has been mailed (Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(contested_appeal, contested)
        allow(contested_appeal).to receive(:contested_claim?).and_return(true)
        contested_appeal.contested_claim?
        contested_dispatch.complete_dispatch_root_task!
      end
    end
  end

  describe HearingScheduled do
    describe "#create_hearing" do
      let(:appeal_hearing) { create(:appeal, :with_schedule_hearing_tasks) }
      let(:template_name) { "HearingScheduled" }
      let(:schedule_hearing_task) { ScheduleHearingTask.find_by(appeal: appeal_hearing) }
      let(:task_values) do
        {
          appeal: appeal_hearing,
          hearing_day_id: create(:hearing_day).id,
          hearing_location_attributes: {},
          scheduled_time_string: "11:30am",
          notes: "none"
        }
      end
      it "will notify appellant when a hearing is scheduled" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal_hearing, template_name)
        schedule_hearing_task.create_hearing(task_values)
      end
    end
  end

  describe HearingPostponed do
    describe "#postpone!" do
      let(:template_name) { "HearingPostponed" }
      let(:postponed_hearing) { create(:hearing, :postponed, :with_tasks) }
      let(:hearing_hash) { { disposition: "postponed" } }
      it "will notify appellant when a hearing is postponed" do
        appeal_hearing = postponed_hearing.appeal
        hearing_disposition_task = appeal_hearing.tasks.find_by(type: "AssignHearingDispositionTask")
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal_hearing, template_name)
        hearing_disposition_task.update_hearing(hearing_hash)
      end
    end
  end

  describe HearingWithdrawn do
    describe "#cancel!" do
      let(:template_name) { "HearingWithdrawn" }
      let(:withdrawn_hearing) { create(:hearing, :cancelled, :with_tasks) }
      let(:hearing_hash) { { disposition: "cancelled" } }
      it "will notify appellant when a hearing is withdrawn/cancelled" do
        appeal = withdrawn_hearing.appeal
        hearing_disposition_task = appeal.tasks.find_by(type: "AssignHearingDispositionTask")
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        hearing_disposition_task.update_hearing(hearing_hash)
      end
    end
  end

  describe "FOIA/Privacy Act tasks" do
    let(:template_pending) { "PrivacyActPending" }
    let(:template_closed) { "PrivacyActComplete" }

    context "HearingAdminFoiaPrivacyRequestTask" do
      let!(:veteran) { create(:veteran) }
      let!(:appeal) { create(:appeal, veteran: veteran) }
      let!(:hearings_management_user) { create(:hearings_coordinator) }
      let!(:parent_task) { create(:schedule_hearing_task, appeal: appeal) }
      let(:task_params_org) do
        {
          instructions: "seijhy7fa",
          type: "HearingAdminActionFoiaPrivacyRequestTask",
          assigned_to: HearingsManagement
        }
      end
      let(:task_params_user) do
        {
          instructions: "djfkdjfkd",
          type: "HearingAdminActionFoiaPrivacyRequestTask",
          assigned_to: hearings_management_user
        }
      end
      before do
        HearingsManagement.singleton.add_user(hearings_management_user)
        RequestStore[:current_user] = hearings_management_user
      end

      it "calls notify_appellant when task is created" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
        HearingAdminActionFoiaPrivacyRequestTask.create_child_task(parent_task, hearings_management_user, task_params_org)
      end
      it "calls notify_appellant when task is completed" do
        task_org = HearingAdminActionFoiaPrivacyRequestTask.find_by(appeal: appeal)
        # create child task and close it
        task_user = HearingAdminActionFoiaPrivacyRequestTask.create_child_task(task_org, hearings_management_user, task_params_user)
        task_user.update!(status: "completed")
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        task_org.update_status_if_children_tasks_are_closed(task_user)
      end
    end

    # Note: only privacyactrequestmailtask is tested because the process is the same as foiarequestmailtask
    describe "mail task" do
      let!(:veteran) { create(:veteran) }
      let!(:appeal) { create(:appeal, veteran: veteran) }
      let!(:current_user) { create(:user) }
      let(:mail_team) { MailTeam.singleton }
      let(:parent_task) { create(:root_task) }
      before do
        mail_team.add_user(user)
      end
      context "PrivacyActRequestMailTask" do
        let(:task_params) do
          {
            type: "PrivacyActRequestMailTask"
          }
        end
        it "PrivacyActPending" do
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
          parent_task.create_twin_of_type(task_params)
        end
        it "PrivacyActComplete" do
          task_user = PrivacyActRequestMailTask.find_by(appeal: appeal, assigned_to_type: "User")
          task_user.update!(status: "completed")
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
          task_org = PrivacyActRequestMailTask.find_by(appeal: appeal, assigned_to_type: "Organization")
          task_org.update_status_if_children_tasks_are_closed(task_user)
        end
      end
    end

    context "Colocated Tasks" do
      let!(:attorney) { create(:user) }
      let!(:attorney_task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney) }
      let(:vlj_admin) do
        user = create(:user)
        OrganizationsUser.make_user_admin(user, Colocated.singleton)
        user
      end
      let(:task_params) do
        {
          instructions: "djfkdjf",
          type: "FoiaColocatedTask",
          external_id: appeal.uuid,
          parent_id: attorney_task.id
        }
      end
      let(:privacy_params_org) do
        {
          instructions: "kjkjk",
          type: "PrivacyActTask",
          assigned_to: Colocated.singleton
        }
      end
      let(:privacy_params_user) do
        {
          instructions: "kjkjk",
          type: "PrivacyActTask",
          assigned_to: vlj_admin
        }
      end
      it "sends notification when creating a FoiaColocatedTask" do
        org_task = ColocatedTask.create_from_params(task_params, attorney)
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
        org_task.create_privacy_act_task
      end
      it "sends notification when creating a PrivacyActTask" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        Task.create_child_task(org_task, attorney, privacy_params_org)
      end
      it "sends notification when completing a PrivacyActTask" do
        privacy_org_task = PrivacyActTask.find_by(appeal: appeal)
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        privacy_org_task.create_child_task(privacy_org_task, vlj_admin, privacy_params_user)

      end
      it "sends notification when completing a FoiaColocatedTask" do

        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)

      end
    end
  end
  describe IhpTaskPending do
    describe "create_ihp_tasks!" do
      let(:appeal) { create(:appeal, :active) }
      let(:root_task) { RootTask.find_by(appeal: appeal) }
      let(:task_factory) { IhpTasksFactory.new(root_task) }
      let(:template_name) { "IhpTaskPending" }
      it "will notify appellant of 'IhpTaskPending' status" do
        expect(AppellantNotification).to receive(:notify_appellant).with(root_task.appeal, template_name)
        task_factory.create_ihp_tasks!
      end
    end

    describe "notify_appellant_if_ihp(appeal)" do
      context "A newly created 'IhpColocatedTask'" do
        let(:user) { create(:user) }
        let(:org) { create(:organization) }
        let(:task) { create(:colocated_task, :ihp, :in_progress, assigned_to: org) }
        let(:name) { task.type }
        let(:template_name) { "IhpTaskPending" }
        it "will notify the appellant of the 'IhpTaskPending' status" do
          expect(AppellantNotification).to receive(:notify_appellant).with(task.appeal, template_name)
          notify_appellant_if_ihp(task.appeal)
        end
      end
    end
  end

  describe IhpTaskComplete do
    describe "update_from_params" do
      context "A completed 'IhpColocatedTask'" do
        let(:user) { create(:user) }
        let(:org) { create(:organization) }
        let(:task) { create(:colocated_task, :ihp, :in_progress, assigned_to: org) }
        let(:template_name) { "IhpTaskComplete" }
        it "will notify the appellant of the 'IhpTaskComplete' status" do
          allow(task).to receive(:verify_user_can_update!).with(user).and_return(true)
          expect(AppellantNotification).to receive(:notify_appellant).with(task.appeal, template_name)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed, instructions: "Test" }, user)
        end
      end
    end

    describe "update_from_params" do
      context "A completed 'InformalHearingPresentationTask'" do
        let(:user) { create(:user) }
        let(:org) { create(:organization) }
        let(:task) { create(:informal_hearing_presentation_task, :in_progress, assigned_to: org) }
        let(:template_name) { "IhpTaskComplete" }
        it "will notify the appellant of the 'IhpTaskComplete' status" do
          allow(task).to receive(:verify_user_can_update!).with(user).and_return(true)
          expect(AppellantNotification).to receive(:notify_appellant).with(task.appeal, template_name)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed, instructions: "Test" }, user)
        end
      end
    end
  end
end
