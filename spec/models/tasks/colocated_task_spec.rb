# frozen_string_literal: true

describe ColocatedTask do
  let(:attorney) { User.create(css_id: "CFS456", station_id: User::BOARD_STATION_ID) }
  let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let(:vacols_case) { create(:case) }
  let!(:appeal_1) { create(:legacy_appeal, vacols_case: vacols_case) }
  let!(:colocated_org) { Colocated.singleton }
  let(:colocated_members) { FactoryBot.create_list(:user, 3) }

  before do
    colocated_members.each do |u|
      OrganizationsUser.add_user_to_organization(u, colocated_org)
    end

    RequestStore.store[:current_user] = attorney
  end

  context ".create_many_from_params" do
    context "all fields are present and it is a legacy appeal" do
      let!(:appeal_2) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:appeal_3) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:appeal_4) { create(:legacy_appeal, vacols_case: create(:case)) }
      let(:task_params_1) { { assigned_by: attorney, action: :aoj, appeal: appeal_1 } }
      let(:task_params_2) { { assigned_by: attorney, action: :poa_clarification, appeal: appeal_1 } }
      let(:task_params_list) { [task_params_1, task_params_2] }

      subject { ColocatedTask.create_many_from_params(task_params_list, attorney) }

      context "creating one task" do
        let(:task_params_list) { [task_params_1] }

        it "creates co-located tasks and updates the VACOLS location" do
          expect(vacols_case.bfcurloc).to be_nil
          expect(Task.where(type: ColocatedTask.name).count).to eq 0

          team_task = subject.detect { |t| t.assigned_to.is_a?(Colocated) }
          expect(team_task.valid?).to be true
          expect(team_task.status).to eq(Constants.TASK_STATUSES.on_hold)
          expect(team_task.assigned_to).to eq(Colocated.singleton)

          user_task = subject.detect { |t| t.assigned_to.is_a?(User) }
          expect(user_task.valid?).to be true
          expect(user_task.status).to eq "assigned"
          expect(user_task.assigned_at).to_not eq nil
          expect(user_task.assigned_by).to eq attorney
          expect(user_task.action).to eq "aoj"
          expect(user_task.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
          expect(Task.where(type: ColocatedTask.name).count).to eq 2
        end
      end

      it "assigns tasks on the same appeal to the same user" do
        user_tasks = subject.select { |t| t.assigned_to.is_a?(User) }
        expect(user_tasks.first.valid?).to be true
        expect(user_tasks.first.status).to eq "assigned"
        expect(user_tasks.first.action).to eq "aoj"
        expect(user_tasks.first.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)

        expect(user_tasks.second.valid?).to be true
        expect(user_tasks.second.status).to eq "assigned"
        expect(user_tasks.second.action).to eq "poa_clarification"
        expect(user_tasks.second.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)
      end

      it "assigns tasks on the same appeal to the same user when they're not the next assignee" do
        user_tasks = subject.select { |t| t.assigned_to.is_a?(User) }
        expect(user_tasks.first.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)
        expect(user_tasks.second.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, action: :aoj, appeal: appeal_2 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by(css_id: colocated_members[1].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, action: :aoj, appeal: appeal_3 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by(css_id: colocated_members[2].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, action: :aoj, appeal: appeal_4 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)

        record = ColocatedTask.create_many_from_params(
          [{ assigned_by: attorney, action: :poa_clarification, appeal: appeal_3 }], attorney
        )
        expect(record.second.assigned_to).to eq User.find_by(css_id: colocated_members[2].css_id)
      end
    end

    context "when all fields are present and it is an ama appeal" do
      subject do
        ColocatedTask.create_many_from_params([{
                                                assigned_by: attorney,
                                                action: :aoj,
                                                parent: create(:ama_attorney_task),
                                                appeal: create(:appeal)
                                              }], attorney)
      end

      it "creates a co-located task successfully and does not update VACOLS location" do
        expect(subject.first.valid?).to be true
        expect(subject.first.reload.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(subject.first.assigned_at).to_not eq nil
        expect(subject.first.assigned_by).to eq attorney
        expect(subject.first.action).to eq "aoj"
        expect(subject.first.assigned_to).to eq(Colocated.singleton)

        expect(subject.second.valid?).to be true
        expect(subject.second.reload.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(subject.second.assigned_at).to_not eq nil
        expect(subject.second.assigned_by).to eq attorney
        expect(subject.second.action).to eq "aoj"
        expect(subject.second.assigned_to).to eq User.find_by(css_id: colocated_members[0].css_id)

        expect(AppealRepository).to_not receive(:update_location!)
      end
    end

    context "when appeal is missing" do
      subject { ColocatedTask.create_many_from_params([{ assigned_by: attorney, action: :aoj }], attorney) }

      it "does not create a co-located task" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /Appeal can't be blank/)
        expect(ColocatedTask.all.count).to eq 0
      end
    end

    context "when action is not valid" do
      subject do
        ColocatedTask.create_many_from_params([{ assigned_by: attorney, action: :test, appeal: appeal_1 }], attorney)
      end

      it "does not create a co-located task" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, /Action is not included in the list/)
        expect(ColocatedTask.all.count).to eq 0
      end
    end
  end

  context ".update" do
    let(:colocated_admin_action) do
      atty = FactoryBot.create(:user)
      FactoryBot.create(:staff, :attorney_role, sdomainid: atty.css_id)

      ColocatedTask.find(FactoryBot.create(:colocated_task, assigned_by: atty).id)
    end

    context "when status is updated to on-hold" do
      it "should validate on-hold duration" do
        colocated_admin_action.update(status: Constants.TASK_STATUSES.on_hold)
        expect(colocated_admin_action.valid?).to eq false
        expect(colocated_admin_action.errors.messages[:on_hold_duration]).to eq ["has to be specified"]

        colocated_admin_action.update(status: Constants.TASK_STATUSES.in_progress)
        expect(colocated_admin_action.valid?).to eq true

        colocated_admin_action.update(status: Constants.TASK_STATUSES.on_hold, on_hold_duration: 60)
        expect(colocated_admin_action.valid?).to eq true
      end
    end

    context "when status is updated to completed" do
      let!(:staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
      let(:colocated_admin_action) do
        ColocatedTask.create_many_from_params([{
                                                appeal: appeal_1,
                                                appeal_type: "LegacyAppeal",
                                                assigned_by: attorney,
                                                assigned_to: create(:user),
                                                action: action
                                              }], attorney).last
      end

      context "when more than one task per appeal and not all colocated tasks are completed" do
        let(:action) { :poa_clarification }

        let!(:colocated_admin_action2) do
          ColocatedTask.create_many_from_params([{
                                                  appeal: appeal_1,
                                                  appeal_type: "LegacyAppeal",
                                                  assigned_by: attorney,
                                                  assigned_to: create(:user),
                                                  action: :poa_clarification
                                                }], attorney)
        end

        it "should not update location to assignor in vacols" do
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to_not eq staff.slogid
        end
      end

      context "when completing a translation task" do
        let(:action) { :translation }
        it "should update location to translation in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:translation]
        end
      end

      context "when completing a schedule hearing task" do
        let(:action) { :schedule_hearing }
        let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal_1) }

        it "should update location to schedule hearing in vacols" do
          expect(vacols_case.bfcurloc).to_not eq staff.slogid
          colocated_admin_action.update!(status: Constants.TASK_STATUSES.completed)
          expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[:caseflow]
          expect(appeal_1.tasks.pluck(:type).to_a).to include(ScheduleHearingTask.name)
        end
      end

      context "when all colocated tasks are completed for this appeal" do
        let(:judge) { create(:user) }
        let!(:staff2) { create(:staff, :judge_role, sdomainid: judge.css_id) }
        let(:action) { :poa_clarification }

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
        colocated_admin_action.update(status: "on_hold", on_hold_duration: 30)
        expect(colocated_admin_action.reload.started_at).to eq time1
        expect(colocated_admin_action.placed_on_hold_at).to eq time3

        time4 = Time.utc(2015, 1, 6, 12, 0, 0)
        Timecop.freeze(time4)
        colocated_admin_action.update(status: "on_hold", on_hold_duration: 30)
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
        expect(colocated_admin_action.closed_at).to eq time6
      end
    end
  end

  describe ".available_actions_unwrapper" do
    let(:colocated_user) { FactoryBot.create(:user) }
    let(:colocated_task) do
      # We expect all ColocatedTasks that are assigned to individuals to have parent tasks assigned to the organization.
      org_task = FactoryBot.create(:colocated_task, assigned_by: attorney, assigned_to: Colocated.singleton)
      FactoryBot.create(
        :colocated_task,
        assigned_by: attorney,
        assigned_to: colocated_user,
        parent: org_task
      ).becomes(ColocatedTask)
    end

    it "should vary depending on status of task" do
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to_not eq(0)

      colocated_task.update!(status: Constants.TASK_STATUSES.completed)
      expect(colocated_task.available_actions_unwrapper(colocated_user).count).to eq(0)
    end

    context "when current user is Colocated admin but not task assignee" do
      let(:colocated_admin) { FactoryBot.create(:user) }
      before { OrganizationsUser.make_user_admin(colocated_admin, colocated_org) }

      it "should include only the reassign action" do
        expect(colocated_task.available_actions_unwrapper(colocated_admin).count).to eq(1)
        expect(colocated_task.available_actions_unwrapper(colocated_admin).first[:label]).to(
          eq(Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label)
        )
      end
    end
  end

  describe "round robin assignment skips admins" do
    context "when there is one admin and one non admin in the organization" do
      let(:non_admin) { FactoryBot.create(:user) }
      let(:admin) { FactoryBot.create(:user) }
      let(:task_count) { 6 }

      before do
        colocated_org.users.delete_all
        OrganizationsUser.add_user_to_organization(non_admin, colocated_org)
        OrganizationsUser.add_user_to_organization(admin, colocated_org).update!(admin: true)
      end

      it "should assign all tasks to the non-admin user" do
        task_count.times do
          ColocatedTask.create_many_from_params([{
                                                  assigned_by: attorney,
                                                  action: :aoj,
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
    let(:colocated_user) { FactoryBot.create(:user) }

    before do
      OrganizationsUser.add_user_to_organization(colocated_user, org)
    end

    let(:org_task) { FactoryBot.create(:colocated_task, assigned_by: attorney, assigned_to: org) }
    let(:colocated_task) { org_task.children.first }

    it "assigns the parent task back to the organization" do
      expect(org_task.status).to eq Constants.TASK_STATUSES.on_hold
      colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
      expect(org_task.status).to eq Constants.TASK_STATUSES.completed
    end

    context "for legacy appeals, the new assigned to location is set correctly" do
      let(:legacy_org_translation_task) do
        FactoryBot.create(
          :colocated_task,
          assigned_by: attorney,
          assigned_to: org,
          action: :translation
        )
      end
      let(:legacy_colocated_task) { legacy_org_translation_task.children.first }
      let(:translation_location_code) { LegacyAppeal::LOCATION_CODES[:translation] }

      it "for translation and schedule hearing tasks, it assigns back to those locations" do
        legacy_colocated_task.update!(status: Constants.TASK_STATUSES.cancelled)
        expect(legacy_org_translation_task.appeal.location_code).to eq translation_location_code
      end

      let(:legacy_org_task) do
        FactoryBot.create(
          :colocated_task,
          assigned_by: attorney,
          assigned_to: org,
          action: :aoj
        )
      end
      let(:legacy_colocated_task_2) { legacy_org_task.children.first }

      it "for all other org tasks, it assigns back to the assigner" do
        legacy_colocated_task_2.update!(status: Constants.TASK_STATUSES.cancelled)
        expect(legacy_org_task.appeal.location_code).to eq attorney.vacols_uniq_id
      end
    end
  end
end
