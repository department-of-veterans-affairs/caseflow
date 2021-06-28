# frozen_string_literal: true

describe ColocatedTask, :all_dbs do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let(:vacols_case) { create(:case) }
  let!(:appeal_1) { create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:root_task) { create(:root_task, appeal: appeal_1) }
  let!(:colocated_org) { Colocated.singleton }
  let(:colocated_members) { create_list(:user, 3) }
  let(:params_list) { [] }

  subject { ColocatedTask.create_many_from_params(params_list, attorney) }

  before do
    colocated_members.each do |u|
      colocated_org.add_user(u)
    end

    RequestStore.store[:current_user] = attorney
  end

  context ".create_many_from_params" do
    context "all fields are present and it is a legacy appeal" do
      let!(:appeal_2) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:root_task2) { create(:root_task, appeal: appeal_2) }
      let!(:appeal_3) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:root_task3) { create(:root_task, appeal: appeal_3) }
      let!(:appeal_4) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:root_task4) { create(:root_task, appeal: appeal_4) }
      let(:task_params_1) { { assigned_by: attorney, type: AojColocatedTask.name, appeal: appeal_1 } }
      let(:task_params_2) { { assigned_by: attorney, type: PoaClarificationColocatedTask.name, appeal: appeal_1 } }
      let(:params_list) { [task_params_1, task_params_2] }

      context "creating one task" do
        let(:params_list) { [task_params_1] }

        it "creates co-located tasks and updates the VACOLS location" do
          expect(vacols_case.bfcurloc).to be_nil
          expect(ColocatedTask.count).to eq(0)
          expect(AojColocatedTask.count).to eq(0)

          team_task = subject.detect { |t| t.assigned_to.is_a?(Colocated) }
          expect(team_task.valid?).to be true
          expect(team_task.status).to eq(Constants.TASK_STATUSES.on_hold)
          expect(team_task.assigned_to).to eq(Colocated.singleton)

          user_task = subject.detect { |t| t.assigned_to.is_a?(User) }
          expect(user_task.valid?).to be true
          expect(user_task.status).to eq "assigned"
          expect(user_task.assigned_at).to_not eq nil
          expect(user_task.assigned_by).to eq attorney
          expect(user_task).to be_a(AojColocatedTask)
          expect(user_task.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
          expect(ColocatedTask.count).to eq(2)
          expect(AojColocatedTask.count).to eq(2)
        end
      end

      it "assigns tasks on the same appeal to the same user" do
        user_tasks = subject.select { |t| t.assigned_to.is_a?(User) }
        expect(user_tasks.first.valid?).to be true
        expect(user_tasks.first.status).to eq "assigned"
        expect(user_tasks.first).to be_a(AojColocatedTask)
        expect(user_tasks.first.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)

        expect(user_tasks.second.valid?).to be true
        expect(user_tasks.second.status).to eq "assigned"
        expect(user_tasks.second).to be_a(PoaClarificationColocatedTask)
        expect(user_tasks.second.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)
      end

      it "assigns tasks on the same appeal to the same user when they're not the next assignee" do
        user_tasks = subject.select { |t| t.assigned_to.is_a?(User) }
        expect(user_tasks.first.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)
        expect(user_tasks.second.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, type: AojColocatedTask.name, appeal: appeal_2 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by_css_id(colocated_members[1].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, type: AojColocatedTask.name, appeal: appeal_3 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by_css_id(colocated_members[2].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, type: AojColocatedTask.name, appeal: appeal_4 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, type: PoaClarificationColocatedTask.name, appeal: appeal_3 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by_css_id(colocated_members[2].css_id)
      end
    end

    context "when all fields are present and it is an ama appeal" do
      let(:params_list) do
        [{
          assigned_by: attorney,
          type: AojColocatedTask.name,
          parent: create(:ama_attorney_task),
          appeal: create(:appeal)
        }]
      end

      it "creates a co-located task successfully and does not update VACOLS location" do
        expect(subject.first.valid?).to be true
        expect(subject.first.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first).to be_a(AojColocatedTask)
        expect(subject.first.assigned_to).to eq(Colocated.singleton)

        expect(subject.second.valid?).to be true
        expect(subject.second.reload.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(subject.second.assigned_at).to_not eq nil
        expect(subject.second.assigned_by).to eq attorney
        expect(subject.second).to be_a(AojColocatedTask)
        expect(subject.second.assigned_to).to eq User.find_by_css_id(colocated_members[0].css_id)

        expect(AppealRepository).to_not receive(:update_location!)
      end
    end

    context "when action is :schedule_hearing, :missing_hearing_transcripts, :foia, or :translation" do
      let(:params_list) do
        [ScheduleHearingColocatedTask, MissingHearingTranscriptsColocatedTask, FoiaColocatedTask,
         TranslationColocatedTask].map do |colocated_subclass|
          {
            assigned_by: attorney,
            type: colocated_subclass.name,
            parent: create(:ama_attorney_task),
            appeal: create(:legacy_appeal, vacols_case: create(:case))
          }
        end
      end

      it "should route to the correct teams and create the correct children" do
        hearing_task, transcription_task, transcription_child_task, foia_task, foia_child_task,
          translation_task, translation_child_task = subject

        expect(hearing_task.is_a?(ScheduleHearingColocatedTask)).to eq true
        expect(hearing_task.assigned_to).to eq(HearingsManagement.singleton)

        expect(transcription_task.is_a?(MissingHearingTranscriptsColocatedTask)).to eq true
        expect(transcription_task.assigned_to).to eq(TranscriptionTeam.singleton)
        expect(transcription_task.children.first).to eq transcription_child_task
        expect(transcription_child_task.is_a?(TranscriptionTask)).to eq true

        expect(foia_task.is_a?(FoiaColocatedTask)).to eq true
        expect(foia_task.assigned_to).to eq(PrivacyTeam.singleton)
        expect(foia_task.children.first).to eq foia_child_task
        expect(foia_child_task.is_a?(FoiaTask)).to eq true

        expect(translation_task.is_a?(TranslationColocatedTask)).to eq true
        expect(translation_task.assigned_to).to eq(Translation.singleton)
        expect(translation_task.children.first).to eq translation_child_task
        expect(translation_child_task.is_a?(TranslationTask)).to eq true
        expect(translation_task.appeal.case_record.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
      end
    end

    context "when appeal is missing" do
      let(:params_list) { [{ assigned_by: attorney, type: AojColocatedTask.name }] }

      it "does not create a co-located task" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /Appeal can't be blank/)
        expect(ColocatedTask.all.count).to eq 0
      end
    end

    context "when trying to create muliple identical tasks" do
      let!(:parent) { create(:ama_attorney_task, parent: root_task, assigned_to: attorney) }
      let(:instructions) { "These are my instructions" }
      let(:task_params) do
        {
          appeal: appeal_1,
          assigned_by: attorney,
          assigned_to: colocated_org,
          type: PoaClarificationColocatedTask.name,
          parent: parent,
          instructions: [instructions]
        }
      end

      context "at the same time" do
        let(:params_list) { [task_params, task_params] }

        it "does not create any co-located tasks" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /already an open POA CLARIFICATION action/)
          expect(ColocatedTask.all.count).to eq 0
        end
      end

      context "when one already exists" do
        let(:params_list) { [task_params] }
        let!(:existing_action) do
          create(
            :colocated_task,
            :poa_clarification,
            appeal: appeal_1,
            assigned_by: attorney,
            assigned_to: colocated_org,
            parent: parent,
            instructions: [instructions]
          )
        end

        it "does not create a new co-located task" do
          before_count = ColocatedTask.all.count
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /already an open POA CLARIFICATION action/)
          expect(ColocatedTask.all.count).to eq before_count
        end
      end
    end

    context "when user is not a judge or an attorney" do
      let(:params_list) { [{ assigned_by: attorney, type: IhpColocatedTask.name, appeal: appeal_1 }] }

      before { allow_any_instance_of(User).to receive(:attorney_in_vacols?).and_return(false) }

      it "throws an error" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError, /Current user cannot access this task/)
        expect(ColocatedTask.all.count).to eq 0
      end
    end

    context "When trying to create an invalid task type" do
      let(:type) { PreRoutingFoiaColocatedTask.name }
      let(:params_list) { [{ assigned_by: attorney, type: type, appeal: appeal_1 }] }

      it "throws an error" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError, /Cannot create task of type #{type}/)
        expect(ColocatedTask.all.count).to eq 0
      end
    end
  end

  context ".update" do
    let!(:attorney_2) { create(:user) }
    let!(:staff_2) { create(:staff, :attorney_role, sdomainid: attorney_2.css_id) }
    let(:org_colocated_task) { create(:colocated_task, assigned_by: attorney_2) }
    let!(:colocated_admin_action) { org_colocated_task.children.first }

    context "when status is updated to completed" do
      let(:colocated_admin_action) do
        ColocatedTask.create_many_from_params([{
                                                appeal: appeal_1,
                                                appeal_type: "LegacyAppeal",
                                                assigned_by: attorney,
                                                assigned_to: create(:user),
                                                type: colocated_subclass.name,
                                                instructions: ["second"]
                                              }], attorney).last
      end

      context "when more than one task per appeal and not all colocated tasks are completed" do
        let(:colocated_subclass) { PoaClarificationColocatedTask }
        let!(:colocated_admin_action_2) do
          ColocatedTask.create_many_from_params([{
                                                  appeal: appeal_1,
                                                  appeal_type: "LegacyAppeal",
                                                  assigned_by: attorney,
                                                  assigned_to: create(:user),
                                                  type: PoaClarificationColocatedTask.name
                                                }], attorney)
        end

        it "should not update location to assignor in vacols" do
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to_not eq staff.slogid
        end
      end

      context "when completing a translation task" do
        let(:colocated_subclass) { TranslationColocatedTask }
        it "should update location to the assigner in vacols" do
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to eq staff.slogid
        end
      end

      context "when completing a schedule hearing task" do
        let(:colocated_subclass) { ScheduleHearingColocatedTask }
        it "should create a schedule hearing task" do
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
          expect(appeal_1.root_task.children.empty?)
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:schedule_hearing]
        end
      end

      context "when all colocated tasks are completed for this appeal" do
        let(:judge) { create(:user) }
        let!(:staff2) { create(:staff, :judge_role, sdomainid: judge.css_id) }
        let(:colocated_subclass) { PoaClarificationColocatedTask }

        let!(:task2) do
          AttorneyTask.create!(
            appeal: appeal_1,
            appeal_type: "LegacyAppeal",
            assigned_by: judge,
            assigned_to: attorney
          )
        end

        it "should update location to assignor in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to eq staff.slogid
        end
      end
    end

    context "when status is updated" do
      it "should reset timestamps only if status has changed" do
        time1 = Time.utc(2015, 1, 1, 12, 0, 0)
        Timecop.freeze(time1)
        colocated_admin_action.update(status: "in_progress")
        expect(colocated_admin_action.reload.started_at).to eq time1

        time2 = Time.utc(2015, 1, 3, 12, 0, 0)
        Timecop.freeze(time2)
        colocated_admin_action.update(status: "in_progress")
        # time should not change
        expect(colocated_admin_action.reload.started_at).to eq time1

        time3 = Time.utc(2015, 1, 5, 12, 0, 0)
        Timecop.freeze(time3)
        colocated_admin_action.update(status: "on_hold")
        expect(colocated_admin_action.reload.started_at).to eq time1
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time4 = Time.utc(2015, 1, 6, 12, 0, 0)
        Timecop.freeze(time4)
        colocated_admin_action.update(status: "on_hold")
        # neither dates should change
        expect(colocated_admin_action.reload.started_at).to eq time1
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time5 = Time.utc(2015, 1, 7, 12, 0, 0)
        Timecop.freeze(time5)
        colocated_admin_action.update(status: "in_progress")
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time6 = Time.utc(2015, 1, 8, 12, 0, 0)
        Timecop.freeze(time6)
        colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3
        expect(colocated_admin_action.closed_at).to eq time6

        time7 = Time.utc(2015, 1, 9, 12, 0, 0)
        Timecop.freeze(time7)
        colocated_admin_action.update(status: "assigned")
        # go back to in-progres - should reset date
        expect(colocated_admin_action.reload.started_at).to eq time5
        expect(colocated_admin_action.placed_on_hold_at).to eq time3
        expect(colocated_admin_action.closed_at).to be_nil
      end
    end
  end

  describe ".available_actions_unwrapper" do
    let(:colocated_user) { create(:user) }
    let(:colocated_task) do
      # We expect all ColocatedTasks that are assigned to individuals to have parent tasks assigned to the organization.
      org_task = create(:colocated_task, appeal: appeal_1, assigned_by: attorney)
      create(
        :colocated_task,
        assigned_by: attorney,
        assigned_to: colocated_user,
        parent: org_task
      )
    end

    it "should vary depending on status of task" do
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to_not eq(0)

      colocated_task.update!(status: Constants.TASK_STATUSES.completed)
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to eq(0)
    end

    context "when current user is Colocated admin but not task assignee" do
      let(:colocated_admin) { create(:user) }
      before { OrganizationsUser.make_user_admin(colocated_admin, colocated_org) }

      it "should include all actions available to the assigned user along with reassign" do
        assigned_user_actions = colocated_task.available_actions_unwrapper(colocated_user)
        expect(colocated_task.available_actions_unwrapper(colocated_admin).count).to eq(assigned_user_actions.size + 1)
        expect(colocated_task.available_actions_unwrapper(colocated_admin)
          .include?(Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label))
      end
    end
  end

  describe "round robin assignment skips admins" do
    context "when there is one admin and one non admin in the organization" do
      let(:non_admin) { create(:user) }
      let(:admin) { create(:user) }
      let(:task_count) { 6 }

      before do
        colocated_org.users.delete_all
        colocated_org.add_user(non_admin)
        colocated_org.add_user(admin).update!(admin: true)
      end

      it "should assign all tasks to the non-admin user" do
        task_count.times do
          ColocatedTask.create_many_from_params([{
                                                  assigned_by: attorney,
                                                  type: AojColocatedTask.name,
                                                  parent: create(:ama_attorney_task),
                                                  appeal: create(:appeal)
                                                }], attorney)
        end

        expect(non_admin.tasks.count).to eq(task_count)
        expect(admin.tasks.count).to eq(0)
      end
    end
  end

  describe "colocated task is cancelled" do
    let(:org) { Colocated.singleton }
    let(:colocated_user) { create(:user) }

    before do
      org.add_user(colocated_user)
    end

    let(:org_task) { create(:colocated_task, assigned_by: attorney, assigned_to: org) }
    let(:colocated_task) { org_task.children.first }

    it "assigns the parent task back to the organization" do
      expect(org_task.status).to eq Constants.TASK_STATUSES.on_hold
      colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
      expect(org_task.status).to eq Constants.TASK_STATUSES.cancelled
    end

    context "for legacy appeals, the new assigned to location is set correctly" do
      let(:org_colocated_task) do
        create(
          :colocated_task,
          task_type_trait,
          appeal: appeal_1,
          assigned_by: attorney
        )
      end
      let(:legacy_colocated_task) { org_colocated_task.children.first }

      before do
        org_colocated_task.appeal.case_record&.update!(bfcurloc: location_code)
      end

      context "when the location code is CASEFLOW" do
        let(:location_code) { LegacyAppeal::LOCATION_CODES[:caseflow] }

        context "for AOJ ColocatedTask" do
          let(:task_type_trait) { :aoj }

          it "assigns back to the assigner" do
            legacy_colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
            expect(org_colocated_task.reload.appeal.location_code).to eq(attorney.vacols_uniq_id)
          end
        end

        context "for schedule hearing colocated task" do
          let(:task_type_trait) { :schedule_hearing }

          it "should not create a schedule hearing task" do
            expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
            expect(org_colocated_task.appeal.root_task.children.empty?)
            org_colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
            expect(org_colocated_task.reload.appeal.location_code).to eq(attorney.vacols_uniq_id)
            expect(org_colocated_task.appeal.root_task.children.empty?)
          end
        end
      end

      context "when the location code is not CASEFLOW" do
        let(:task_type_trait) { ColocatedTask.actions_assigned_to_colocated.sample.to_sym }
        let(:location_code) { "FAKELOC" }

        it "does not change the case's location_code" do
          legacy_colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
          expect(org_colocated_task.reload.appeal.location_code).to eq(location_code)
        end
      end

      context "when the VACOLS case has been deleted" do
        let!(:appeal_1) { create(:legacy_appeal) }
        let(:task_type_trait) { ColocatedTask.actions_assigned_to_colocated.sample.to_sym }
        let(:location_code) { "FAKELOC" }

        it "does not attempt to access the location code" do
          legacy_colocated_task.cancelled!
          expect(org_colocated_task.reload.appeal.location_code).to be_nil
        end
      end
    end
  end

  describe "Reassigned ColocatedTask for LegacyAppeal" do
    let(:initial_assigner) { create(:user) }
    let!(:initial_assigner_staff) { create(:staff, :attorney_role, sdomainid: initial_assigner.css_id) }
    let(:reassigner) { create(:user) }
    let!(:reassigner_staff) { create(:staff, sdomainid: reassigner.css_id) }

    let(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(:case, bfcurloc: LegacyAppeal::LOCATION_CODES[:caseflow])
      )
    end

    let(:org_task) do
      create(
        :colocated_task,
        :retired_vlj,
        appeal: appeal,
        assigned_by: initial_assigner
      )
    end
    let!(:colocated_task) { org_task.children.first }

    before do
      reassign_params = {
        assigned_to_type: User.name,
        assigned_to_id: Colocated.singleton.next_assignee.id
      }
      colocated_task.reassign(reassign_params, reassigner)
    end

    it "charges the case to the original assigner in VACOLS" do
      # Complete the re-assigned task.
      org_task.children.open.first.update!(status: Constants.TASK_STATUSES.completed)

      # Our AssociatedVacolsModels hold on to their VACOLS properties aggressively. Re-fetch the object to avoid that.
      expect(LegacyAppeal.find(appeal.id).location_code).to eq(initial_assigner.vacols_uniq_id)
    end
  end

  describe "Reassign PreRoutingColocatedTask" do
    let(:task_class) { PreRoutingFoiaColocatedTask }
    let(:parent_task) do
      PreRoutingFoiaColocatedTask.create(
        assigned_by: attorney,
        assigned_to: colocated_org,
        parent: appeal_1.root_task,
        appeal: appeal_1
      )
    end
    let!(:child_task) { parent_task.children.first }
    let(:reassign_params) { { assigned_to_type: User.name, assigned_to_id: Colocated.singleton.next_assignee.id } }

    subject { child_task.reassign(reassign_params, attorney) }

    it "allows the reassign" do
      tasks = subject

      expect(tasks.count).to eq 2
      expect(child_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      expect(parent_task.reload.children.open.first.assigned_to).not_to eq colocated_org.users.first
      expect(parent_task.children.open.first.label).to eq task_class.label
    end
  end

  describe "special handling for Motion to Vacate attorney checkout flow" do
    let(:vacate_type) { "vacate_and_de_novo" }

    let!(:judge) { create(:user, full_name: "Judge the First", css_id: "JUDGE_1") }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let(:receipt_date) { Time.zone.today - 20 }
    let!(:appeal) do
      create(:appeal, receipt_date: receipt_date)
    end

    let!(:decision_issues) do
      3.times do |idx|
        create(
          :decision_issue,
          :rating,
          decision_review: appeal,
          disposition: "denied",
          description: "Decision issue description #{idx}",
          decision_text: "decision issue"
        )
      end
    end

    let!(:root_task) { create(:root_task, appeal: appeal) }

    let!(:motions_attorney) { create(:user, full_name: "Motions attorney") }

    let(:vacate_motion_mail_task) do
      create(:vacate_motion_mail_task, assigned_to: motions_attorney, parent: root_task)
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task,
             appeal: appeal,
             assigned_to: judge,
             parent: vacate_motion_mail_task
      )
    end
    let(:post_decision_motion_params) do
      {
        instructions: "I am granting this",
        disposition: "granted",
        vacate_type: vacate_type,
        assigned_to_id: attorney
      }
    end
    let(:post_decision_motion_updater) do
      PostDecisionMotionUpdater.new(judge_address_motion_to_vacate_task, post_decision_motion_params)
    end
    let(:vacate_stream) do
      Appeal.find_by(stream_docket_number: appeal.docket_number, stream_type: Constants.AMA_STREAM_TYPES.vacate)
    end
    let(:attorney_task) { AttorneyTask.find_by(assigned_to: attorney) }
    let(:parent) { create(:ama_judge_decision_review_task, assigned_to: judge, appeal: vacate_stream ) }

    let(:params_list) do
      [{
        assigned_by: attorney,
        type: AojColocatedTask.name,
        parent_id: parent.id,
        appeal: vacate_stream
      }]
    end

    before do
      create(:staff, :judge_role, sdomainid: judge.css_id)
      judge_team.add_user(attorney)

      FeatureToggle.enable!(:review_motion_to_vacate)

      post_decision_motion_updater.process
      appeal.reload

      judge_address_motion_to_vacate_task.update(status: Constants.TASK_STATUSES.completed)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    context "vacate & de novo" do
      it "passes validation and creates child tasks" do
        expect { subject }.not_to raise_error
        expect(ColocatedTask.all.count).to eq 2
      end
    end

    context "other vacate type" do
      let(:vacate_type) { "straight_vacate" }

      it "doesn't pass" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
        expect(ColocatedTask.all.count).to eq 0
      end
    end
  end
end
