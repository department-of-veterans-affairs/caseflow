# frozen_string_literal: true

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
          expect(AppellantNotification.handle_errors(appeal)[:status]).to eq(
            AppellantNotification::NoClaimantError.new(appeal.id).status
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
          expect(AppellantNotification.handle_errors(appeal)[:status]).to eq(
            AppellantNotification::NoParticipantIdError.new(appeal.id).status
          )
        end
      end

      context "with no errors" do
        it "doesn't raise" do
          expect(AppellantNotification.handle_errors(appeal)[:status]).to eq "Success"
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
            AppellantNotification.create_payload(good_appeal, template_name).status
          ).to eq "Success"
        end
      end

      context "creates a payload with errors" do
        before do
          bad_appeal.claimants = [bad_claimant]
        end
        it "does not have a success status" do
          expect(
            AppellantNotification.create_payload(bad_appeal, template_name).status
          ).not_to eq "Success"
        end
      end
    end
  end
end

describe AppellantNotification do
  describe AppealDocketed do
    describe "docket_appeal" do
      let(:appeal) { create(:appeal, :with_pre_docket_task) }
      let(:template_name) { "Appeal docketed" }
      let(:pre_docket_task) { PreDocketTask.find_by(appeal: appeal) }
      it "will notify appellant that Predocketed Appeal is docketed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
        pre_docket_task.docket_appeal
      end
    end

    describe "create_tasks_on_intake_success!" do
      let(:appeal) { create(:appeal) }
      let(:template_name) { "Appeal docketed" }
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
          appeal: legacy_appeal,
          appeal_type: legacy_appeal.class.to_s,
          appeal_id: legacy_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested) { "Appeal decision mailed (Contested claims)" }
      let(:non_contested) { "Appeal decision mailed (Non-contested claims)" }
      let(:dispatch) { LegacyAppealDispatch.new(appeal: legacy_appeal, params: params) }
      it "Will notify appellant that the legacy appeal decision has been mailed (Non Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(legacy_appeal, non_contested)
        decision_document = dispatch.send "create_decision_document_and_submit_for_processing!", params
        decision_document.process!
      end
      it "Will notify appellant that the legacy appeal decision has been mailed (Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(legacy_appeal, contested)
        allow(legacy_appeal).to receive(:contested_claim).and_return(true)
        legacy_appeal.contested_claim
        decision_document = dispatch.send "create_decision_document_and_submit_for_processing!", params
        decision_document.process!
      end
    end

    describe "AMA Appeal Decision Mailed" do
      let(:appeal) { create(:appeal, :with_assigned_bva_dispatch_task) }
      let(:contested_appeal) { create(:appeal, :with_assigned_bva_dispatch_task, :with_request_issues) }
      let(:params) do
        {
          appeal: appeal,
          appeal_type: appeal.class.to_s,
          appeal_id: appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested_params) do
        {
          appeal: contested_appeal,
          appeal_type: contested_appeal.class.to_s,
          appeal_id: contested_appeal.id,
          citation_number: "A18123456",
          decision_date: Time.zone.today,
          redacted_document_location: "some/filepath",
          file: "some file"
        }
      end
      let(:contested) { "Appeal decision mailed (Contested claims)" }
      let(:non_contested) { "Appeal decision mailed (Non-contested claims)" }
      let(:dispatch) do
        AmaAppealDispatch.new(
          appeal: appeal,
          params: params,
          user: User.find(appeal.tasks.find_by(assigned_to_type: "User").assigned_to_id)
        )
      end
      let(:contested_dispatch) do
        AmaAppealDispatch.new(
          appeal: contested_appeal,
          params: contested_params,
          user: User.find(contested_appeal.tasks.find_by(assigned_to_type: "User").assigned_to_id)
        )
      end
      it "Will notify appellant that the AMA appeal decision has been mailed (Non Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, non_contested)
        decision_document = dispatch.send "create_decision_document_and_submit_for_processing!", params
        decision_document.process!
      end
      it "Will notify appellant that the AMA appeal decision has been mailed (Contested)" do
        expect(AppellantNotification).to receive(:notify_appellant).with(contested_appeal, contested)
        allow(contested_appeal).to receive(:contested_claim?).and_return(true)
        contested_appeal.contested_claim?
        contested_decision_document = contested_dispatch.send "create_decision_document_and_submit_for_processing!", contested_params
        contested_decision_document.process!
      end
    end
  end

  describe HearingScheduled do
    describe "#create_hearing" do
      let(:appeal_hearing) { create(:appeal, :with_schedule_hearing_tasks) }
      let(:template_name) { "Hearing scheduled" }
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
      let(:template_name) { "Postponement of hearing" }
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

  describe DocketHearingPostponed do
    describe ".update_hearing" do
      let!(:user) { create(:user) }
      let(:nyc_ro_eastern) { "RO06" }
      let(:video_type) { HearingDay::REQUEST_TYPES[:video] }
      let(:hearing_day) { create(:hearing_day, regional_office: nyc_ro_eastern, request_type: video_type) }
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }
      context "when a hearing coordinator selects 'postponed' on the daily docket page for an AMA Appeal" do
        let(:template_name) { "Postponement of hearing" }
        let(:params) do
          {
            hearing: hearing.reload,
            virtual_hearing_attributes: {
              appellant_email: "veteran@example.com",
              representative_email: "representative@example.com"
            },
            disposition: Constants.HEARING_DISPOSITION_TYPES.postponed
          }
        end
        let(:hearing_update_form) { HearingUpdateForm.new(params) }
        it "the appellant will be notified that their hearing has been postponed" do
          expect(AppellantNotification).to receive(:notify_appellant).with(hearing.appeal, template_name)
          hearing_update_form.update_hearing
        end
      end
    end
  end

  describe DocketHearingWithdrawn do
    describe ".update_hearing" do
      let!(:user) { create(:user) }
      let(:nyc_ro_eastern) { "RO06" }
      let(:video_type) { HearingDay::REQUEST_TYPES[:video] }
      let(:hearing_day) { create(:hearing_day, regional_office: nyc_ro_eastern, request_type: video_type) }
      let!(:hearing) { create(:hearing, hearing_day: hearing_day) }
      context "when a hearing coordinator selects 'cancelled' on the daily docket page for an AMA Appeal" do
        let(:template_name) { "Withdrawal of hearing" }
        let(:params) do
          {
            hearing: hearing.reload,
            virtual_hearing_attributes: {
              appellant_email: "veteran@example.com",
              representative_email: "representative@example.com"
            },
            disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled
          }
        end
        let(:hearing_update_form) { HearingUpdateForm.new(params) }
        it "the appellant will be notified that their hearing has been withdrawn" do
          expect(AppellantNotification).to receive(:notify_appellant).with(hearing.appeal, template_name)
          hearing_update_form.update_hearing
        end
      end
    end
  end

  describe DocketHearingPostponed do
    let!(:template_name) { "Postponement of hearing" }
    let(:bva) { Bva.singleton }
    let!(:hearing_coord) { create(:user, roles: ["Edit HearSched", "Build HearSched"]) }
    describe ".update_hearing" do
      before do
        Bva.singleton.add_user(hearing_coord)
        RequestStore[:current_user] = hearing_coord
      end
      context "Legacy" do
        # create legacy hearing for "will notify appellant when a hearing is postponed" check
        let(:ro_id) { "RO04" }
        let!(:vacols_case) do
          create(
            :case,
            bfregoff: ro_id,
            bfdocind: HearingDay::REQUEST_TYPES[:video]
          )
        end
        let!(:appeal) do
          create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: ro_id)
        end
        let(:hearing) { create(:legacy_hearing, appeal: appeal) }
        let(:hearing_info) do
          {
            disposition: "postponed"
          }
        end

        # create legacy hearing for "should not notify appellant if a postponed hearing updates to postponed" check
        let(:ro_id_postponed) { "RO05" }
        let!(:vacols_case_postponed) do
          create(
            :case,
            bfregoff: ro_id_postponed,
            bfdocind: HearingDay::REQUEST_TYPES[:video]
          )
        end
        let!(:appeal_postponed) do
          create(:legacy_appeal, vacols_case: vacols_case_postponed, closest_regional_office: ro_id_postponed)
        end
        let(:hearing_postponed) { create(:legacy_hearing, appeal: appeal_postponed, disposition: "P") }

        it "will notify appellant when a hearing is postponed" do
          expect(AppellantNotification).to receive(:notify_appellant).with(hearing.appeal, template_name)
          hearing.update_caseflow_and_vacols(hearing_info)
        end

        it "should not notify appellant if a postponed hearing updates to postponed" do
          expect(AppellantNotification).to_not receive(:notify_appellant).with(hearing_postponed.appeal, template_name)
          hearing_postponed.update_caseflow_and_vacols(hearing_info)
        end
      end
    end
  end

  describe DocketHearingWithdrawn do
    let!(:template_name) { "Withdrawal of hearing" }
    let(:bva) { Bva.singleton }
    let!(:hearing_coord) { create(:user, roles: ["Edit HearSched", "Build HearSched"]) }
    describe ".update_hearing" do
      before do
        Bva.singleton.add_user(hearing_coord)
        RequestStore[:current_user] = hearing_coord
      end
      context "Legacy" do
        # create legacy hearing for "will notify appellant when a hearing is postponed" check
        let(:ro_id) { "RO04" }
        let!(:vacols_case) do
          create(
            :case,
            bfregoff: ro_id,
            bfdocind: HearingDay::REQUEST_TYPES[:video]
          )
        end
        let!(:appeal) do
          create(:legacy_appeal, vacols_case: vacols_case, closest_regional_office: ro_id)
        end
        let(:hearing) { create(:legacy_hearing, appeal: appeal) }
        let(:hearing_info) do
          {
            disposition: "cancelled"
          }
        end
        # create legacy hearing for "should not notify appellant if a cancelled hearing updates to cancelled" check
        let(:ro_id_cancelled) { "RO05" }
        let!(:vacols_case_cancelled) do
          create(
            :case,
            bfregoff: ro_id_cancelled,
            bfdocind: HearingDay::REQUEST_TYPES[:video]
          )
        end
        let!(:appeal_cancelled) do
          create(:legacy_appeal, vacols_case: vacols_case_cancelled, closest_regional_office: ro_id_cancelled)
        end
        let(:hearing_cancelled) { create(:legacy_hearing, appeal: appeal_cancelled, disposition: "C") }

        it "will notify appellant when a hearing is withdrawn/cancelled" do
          expect(AppellantNotification).to receive(:notify_appellant).with(hearing.appeal, template_name)
          hearing.update_caseflow_and_vacols(hearing_info)
        end
        it "should not notify appellant if a cancelled hearing updates to cancelled" do
          expect(AppellantNotification).to_not receive(:notify_appellant).with(hearing_cancelled.appeal, template_name)
          hearing_cancelled.update_caseflow_and_vacols(hearing_info)
        end
      end
    end
  end

  describe "FOIA/Privacy Act tasks" do
    let(:template_pending) { "Privacy Act request pending" }
    let(:template_closed) { "Privacy Act request complete" }

    context "HearingAdminFoiaPrivacyRequestTask" do
      let(:appeal) { create(:appeal) }
      let(:bva) { Bva.singleton }
      let!(:hearings_management_user) { create(:hearings_coordinator) }
      let!(:parent_task) { create(:schedule_hearing_task, appeal: appeal) }
      let(:hafpr_task) do
        HearingAdminActionFoiaPrivacyRequestTask.create!(appeal: appeal, parent_id: parent_task.id, assigned_to: bva)
      end
      let(:hafpr_child) do
        create(
          :hearing_admin_action_foia_privacy_request_task,
          appeal: appeal,
          parent: hafpr_task,
          assigned_to: hearings_management_user
        )
      end
      let(:task_params_org) do
        {
          instructions: "seijhy7fa",
          type: "HearingAdminActionFoiaPrivacyRequestTask",
          external_id: appeal.id,
          parent_id: parent_task.id,
          assigned_to: bva
        }
      end
      before do
        Bva.singleton.add_user(hearings_management_user)
        RequestStore[:current_user] = hearings_management_user
      end

      it "calls notify_appellant when task is created" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
        HearingAdminActionFoiaPrivacyRequestTask.create_child_task(parent_task, hearings_management_user, task_params_org)
      end
      it "calls notify_appellant when task is completed" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        hafpr_child.update!(status: "completed")
      end
    end

    # Note: only privacyactrequestmailtask is tested because the process is the same as foiarequestmailtask
    describe "mail task" do
      let(:appeal) { create(:appeal) }
      let(:current_user) { create(:user) }
      let(:priv_org) { PrivacyTeam.singleton }
      let(:root_task) { create(:root_task) }
      let(:mail_task) { AddressChangeMailTask.create!(appeal: appeal, parent_id: root_task.id, assigned_to: priv_org) }
      let(:foia_task) do
        PrivacyActRequestMailTask.create!(appeal: appeal, parent_id: root_task.id, assigned_to: priv_org)
      end
      let(:foia_child) do
        PrivacyActRequestMailTask.create!(appeal: appeal, parent_id: foia_task.id, assigned_to: current_user)
      end
      before do
        priv_org.add_user(current_user)
      end
      context "PrivacyActRequestMailTask" do
        let(:task_params) do
          {
            type: "PrivacyActRequestMailTask",
            instructions: "fjdkfjwpie"
          }
        end
        it "sends a notification when PrivacyActRequestMailTask is created" do
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
          mail_task.create_twin_of_type(task_params)
        end
        it "sends a notification when PrivacyActRequestMailTask is completed" do
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
          foia_child.update!(status: "completed")
          foia_task.update_status_if_children_tasks_are_closed(foia_child)
        end
        it "does not sends a notification when PrivacyActRequestMailTask is cancelled" do
          expect(AppellantNotification).not_to receive(:notify_appellant).with(appeal, template_closed)
          foia_child.update!(status: "cancelled")
          foia_task.update_status_if_children_tasks_are_closed(foia_child)
        end
      end
    end

    context "Foia Colocated Tasks" do
      let(:appeal) { create(:appeal) }
      let!(:attorney) { create(:user) }
      let!(:attorney_task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney) }
      let(:vlj_admin) do
        user = create(:user)
        OrganizationsUser.make_user_admin(user, Colocated.singleton)
        user
      end

      let(:foia_colocated_task) do
        {
          instructions: "kjkjk",
          type: "FoiaColocatedTask",
          assigned_to: PrivacyTeam.singleton,
          appeal: appeal,
          assigned_by: attorney,
          parent: attorney_task
        }
      end
      it "sends notification when creating a FoiaColocatedTask" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
        ColocatedTask.create_from_params(foia_colocated_task, attorney)
      end
      it "sends notification when completing a FoiaColocatedTask" do
        foia_c_task = ColocatedTask.create_from_params(foia_colocated_task, attorney)
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        foia_c_task.children.first.update!(status: "completed")
      end
      it "does not send a notification when cancelling a FoiaColocatedTask" do
        foia_c_task = ColocatedTask.create_from_params(foia_colocated_task, attorney)
        expect(AppellantNotification).not_to receive(:notify_appellant).with(appeal, template_closed)
        foia_c_task.children.first.update!(status: "cancelled")
      end
    end

    context "Privacy Act Tasks" do
      let(:appeal) { create(:appeal) }
      let(:attorney) { create(:user) }
      let(:current_user) { create(:user) }
      let(:priv_org) { PrivacyTeam.singleton }
      let(:root_task) { create(:root_task) }
      let(:colocated_task) do
        IhpColocatedTask.create!(appeal: appeal, parent_id: root_task.id, assigned_by: attorney, assigned_to: priv_org)
      end
      let(:privacy_params_org) do
        {
          instructions: "seijhy7fa",
          type: "PrivacyActTask",
          external_id: appeal.id,
          parent_id: colocated_task.id,
          assigned_to: priv_org,
          assigned_to_type: "Organization"
        }
      end
      let(:privacy_parent) { PrivacyActTask.create!(appeal: appeal, parent_id: colocated_task.id, assigned_to: priv_org) }
      let(:privacy_child) { PrivacyActTask.create!(appeal: appeal, parent_id: privacy_parent.id, assigned_to: current_user) }
      before do
        priv_org.add_user(current_user)
      end
      it "sends notification when creating a PrivacyActTask" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_pending)
        PrivacyActTask.create_child_task(colocated_task, attorney, privacy_params_org)
      end
      it "sends notification when completing a PrivacyActTask assigned to user" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        privacy_child.update!(status: "completed")
      end
      it "sends notification when completing a PrivacyActTask assigned to organization" do
        expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_closed)
        privacy_parent.update_with_instructions(status: "completed")
      end
    end
  end
  describe IhpTaskPending do
    describe "#create_ihp_tasks!" do
      context "If the appellant has a VSO" do
        let(:participant_id_with_pva) { "1234" }
        let(:appeal) do
          create(:appeal, :active, claimants: [
                  create(:claimant, participant_id: participant_id_with_pva)
                ])
        end
        let(:root_task) { RootTask.find_by(appeal: appeal) }
        let!(:vso) do
          Vso.create(
            name: "Paralyzed Veterans Of America",
            role: "VSO",
            url: "paralyzed-veterans-of-america",
            participant_id: Fakes::BGSServicePOA::PARALYZED_VETERANS_VSO_PARTICIPANT_ID
          )
        end
        let(:task_factory) { IhpTasksFactory.new(root_task) }
        let(:template_name) { "VSO IHP pending" }
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
            .with([participant_id_with_pva]) do
              { participant_id_with_pva => Fakes::BGSServicePOA.paralyzed_veterans_vso_mapped }
            end
        end
        it "The appellant WILL recieve an 'IhpTaskPending' notification" do
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
          task_factory.create_ihp_tasks!
        end
      end
      context "If the appellant does not have a VSO" do
        let(:participant_id_with_nil) { "1234" }
        before do
          allow_any_instance_of(BGSService).to receive(:fetch_poas_by_participant_ids)
            .with([participant_id_with_nil]).and_return(
              participant_id_with_nil => nil
            )
        end
        let(:appeal) do
          create(:appeal, :active, claimants: [create(:claimant, participant_id: participant_id_with_nil)])
        end
        let!(:vso) do
          Vso.create(
            name: "Test VSO",
            url: "test-vso"
          )
        end
        let(:root_task) { RootTask.find_by(appeal: appeal) }
        let(:task_factory) { IhpTasksFactory.new(root_task) }
        let(:template_name) { "VSO IHP pending" }
        it "The appellant will NOT recieve an 'IhpTaskPending' notification" do
          expect(AppellantNotification).not_to receive(:notify_appellant).with(appeal, template_name)
          task_factory.create_ihp_tasks!
        end
      end
    end

    describe "#create_from_params(params, user)" do
      context "When an 'IhpColocatedTask' has been created" do
        let(:user) { create(:user) }
        let(:org) { create(:organization) }
        let(:appeal) { create(:appeal, :active) }
        let(:root_task) { RootTask.find_by(appeal: appeal) }
        let(:attorney) { create(:user) }
        let(:colocated_task) do
          ColocatedTask.create!(appeal: appeal, parent_id: root_task.id, assigned_by: attorney, assigned_to: org)
        end
        let(:template_name) { "VSO IHP pending" }
        let(:params) do
          {
            instructions: "test",
            type: "IhpColocatedTask",
            assigned_to_type: "Organization",
            parent_id: colocated_task.id,
            assigned_to: org,
            appeal: appeal,
            assigned_by: attorney
          }
        end
        it "The appellant will recieve an 'IhpTaskPending' notification" do
          allow(ColocatedTask).to receive(:verify_user_can_create!).with(user, colocated_task).and_return(true)
          expect(AppellantNotification).to receive(:notify_appellant).with(appeal, template_name)
          IhpColocatedTask.create_from_params(params, user)
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
        let(:template_name) { "VSO IHP complete" }
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
        let(:template_name) { "VSO IHP complete" }
        it "will notify the appellant of the 'IhpTaskComplete' status" do
          allow(task).to receive(:verify_user_can_update!).with(user).and_return(true)
          expect(AppellantNotification).to receive(:notify_appellant).with(task.appeal, template_name)
          task.update_from_params({ status: Constants.TASK_STATUSES.completed, instructions: "Test" }, user)
        end
      end
    end
  end

  describe SendNotificationJob do
    let(:appeal) { create(:appeal, :active) }
    let(:template) { "Hearing scheduled" }
    let(:payload) { AppellantNotification.create_payload(appeal, template_name) }
    describe '#perform' do
      it 'pushes a new message' do
        ActiveJob::Base.queue_adapter = :test
        AppellantNotification.notify_appellant(appeal, template)
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
      end
    end
  end
end
