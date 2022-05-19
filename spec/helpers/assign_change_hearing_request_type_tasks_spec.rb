# frozen_string_literal: true

require "./lib/helpers/assign_change_hearing_request_type_tasks.rb"
describe AssignChangeHearingRequestTypeTasks do
  let(:task) { create(:change_hearing_request_type_task, :assigned) }

  describe "#find_open_hearing" do
    context "when a hearing has a disposition of nil" do
      open_hearing = Hearing.new(id: 1, hearing_day_id: 296, disposition: nil)
      hearing_array = [open_hearing]

      it "returns the hearing_day_id of the hearing" do
        expect(AssignChangeHearingRequestTypeTasks.find_open_hearing(hearing_array)) == 296
      end
    end

    context "when a hearing has a disposition that isn't nil" do
      closed_hearing = Hearing.new(id: 2, hearing_day_id: 1, disposition: "held")
      hearing_array = [closed_hearing]

      it "returns nil" do
        expect(AssignChangeHearingRequestTypeTasks.find_open_hearing(hearing_array)).nil?
      end
    end

    context "when there are multiple hearings, return the one that is open" do
      open_hearing = Hearing.new(id: 1, hearing_day_id: 296, disposition: nil)
      closed_hearing = Hearing.new(id: 2, hearing_day_id: 1, disposition: "held")
      hearing_array = [closed_hearing, open_hearing]

      it "returns the open hearing day id only" do
        expect(AssignChangeHearingRequestTypeTasks.find_open_hearing(hearing_array)) == 296
      end
    end
  end

  describe "#get_vso_users_assigned_to_appeal" do
    context "if there are no VSO users assigned to appeal" do
      org_task = Task.new(id: 1, assigned_to_id: 5, assigned_to_type: "Organization")
      tasks_assigned_to_appeal = [org_task]

      it "returns nil" do
        expect(AssignChangeHearingRequestTypeTasks.get_vso_users_assigned_to_appeal(tasks_assigned_to_appeal)).nil?
      end
    end

    context "if there is a VSO user assigned a task" do
      let(:user) { create(:user, id: 24, roles: ["VSO"]) }
      let(:task) { create(:schedule_hearing_task, assigned_to: user, assigned_to_type: "User") }
      subject { AssignChangeHearingRequestTypeTasks.get_vso_users_assigned_to_appeal([task]) }

      it "returns the VSO user" do
        is_expected.to include(user)
      end
    end

    context "if there are multiple VSO users assigned a task to the appeal" do
      let(:vso_users) do
        (1..10).to_a.map { create(:user, roles: ["VSO"]) }
      end
      let(:vso_tasks) do
        vso_users.map do |user|
          create(:schedule_hearing_task, assigned_to: user, assigned_to_type: "User")
        end
      end
      subject { AssignChangeHearingRequestTypeTasks.get_vso_users_assigned_to_appeal(vso_tasks) }

      it "returns all of the VSO users" do
        is_expected.to match_array(vso_users)
      end
    end
  end

  describe "#process_appeals" do
    subject { AssignChangeHearingRequestTypeTasks.process_appeals }

    context "When an appeal without a disposition of hearing is processed" do
      let(:appeal) { create(:appeal, docket_type: "evidence_submission") }

      it "ignores the appeal" do
        is_expected.to eq(nil)
      end
    end

    # new test need to refactor 
    # context "When an appeal has a docket of hearing with no hearing scheduled" do
    #   let(:appeal) { create(:appeal, docket_type: "hearing") }
    #   let(:task) { create(:task, appeal_id: appeal.id, type: "ScheduleHearingTask", status: "active") }
    #   it "the assign_change_hearing_request_type_task method should be called" do
    #     expect(subject).to receive(AssignChangeHearingRequestTypeTasks.assign_change_hearing_request_type_task).with(appeal)
    #   end
    # end
  end

  describe "assign_change_hearing_request_type_task" do
    let(:appeal) { create(:appeal, id: 1) }
    subject { AssignChangeHearingRequestTypeTasks.assign_change_hearing_request_type_task(appeal) }

    context "If there are no open task with ScheduleHearingTask" do
      let(:task) { create(:task, type: "ScheduleHearingTask", appeal_id: appeal.id, status: "closed") }
      

      it "returns nil" do
        is_expected.nil?
      end
    end

    context "If there are no VSO users assigned tasks for the appeal" do
      let(:user) { create(:user, roles: "{EditHearSched}")}
      let(:task) { create(:task, assigned_to: user, type: "ScheduleHearingTask", appeal_id: appeal.id, status: "open") }

      it "returns nil" do
        is_expected.nil?
      end
    end

    context "If there is a VSO user and they have ScheduleHearingTask" do
      let!(:vso) { create(:vso) }
      let!(:vso_user) { create(:user, :vso_role) }
      let!(:root_task) { create(:root_task, appeal: appeal, assigned_to: vso_user) }
      let!(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task, assigned_to: vso_user) }
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task, assigned_to: vso_user) }

        before do
          vso.add_user(vso_user)
          User.authenticate!(user: vso_user)
        end

      it "assigns the task to the VSO user" do
        subject
        vso_user.tasks.where(type: "ChangeHearingRequestTypeTask").nil?
        appeal.tasks.where(type: "ChangeHearingRequestTypeTask").nil?
      end
    end
  end
end
