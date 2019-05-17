# frozen_string_literal: true

require "rails_helper"

describe BulkTaskAssignment do
  describe "#process" do
    context "when all attributes are present" do
      let(:organization) { HearingsManagement.singleton }
      let(:schedule_hearing1) do
        FactoryBot.create(:schedule_hearing_task, assigned_to: organization)
      end
      let(:schedule_hearing2) do
        FactoryBot.create(:schedule_hearing_task, assigned_to: organization)
      end
      let(:assigned_to) { create(:user) }
      let(:assigned_by) { create(:user) }

      it "bulk assigns tasks" do
        params = {
          assigned_to_id: assigned_to.id, 
          assigned_by: assigned_by, 
          organization_id:, 
          task_type: "ScheduleHearingTask", 
          task_count: 2
        }
        result = BulkTaskAssignment.new(params).process
        
      end
    end
  end
end