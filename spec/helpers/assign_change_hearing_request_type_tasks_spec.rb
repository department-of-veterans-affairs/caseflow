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
        expect(AssignChangeHearingRequestTypeTasks.find_open_hearing(hearing_array)) == nil
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
        expect(AssignChangeHearingRequestTypeTasks.get_vso_users_assigned_to_appeal(tasks_assigned_to_appeal)) == nil
      end
    end

    context "if there is a VSO user assigned a task" do
      vso_user_task = Task.new(id: 1, assigned_to_id: 24, assigned_to_type: "User")
      tasks_assigned_to_appeal = [vso_user_task]
      it "return the VSO user" do
        expect(AssignChangeHearingRequestTypeTasks.get_vso_users_assigned_to_appeal(tasks_assigned_to_appeal)) == [User.find_by(id: 24)]
      end
    end
  end
end
