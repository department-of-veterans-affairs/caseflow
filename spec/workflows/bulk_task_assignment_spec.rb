# frozen_string_literal: true

require "rails_helper"

describe BulkTaskAssignment do
  describe "#process" do
    context "when all attributes are present" do
      let(:organization) { HearingsManagement.singleton }
      let!(:schedule_hearing1) do
        FactoryBot.create(
          :no_show_hearing_task, 
          assigned_to: organization, 
          created_at: 5.days.ago)
      end
      let!(:schedule_hearing2) do
        FactoryBot.create(:no_show_hearing_task, 
          assigned_to: organization, 
          created_at: 2.days.ago)
      end
      let(:assigned_to) { create(:user) }
      let(:assigned_by) { create(:user) }

      it "bulk assigns tasks" do
        params = {
          assigned_to_id: assigned_to.id, 
          assigned_by: assigned_by, 
          organization_id: organization.id, 
          task_type: "NoShowHearingTask", 
          task_count: 2
        }
        bulk_assignment = BulkTaskAssignment.new(params)
        expect(bulk_assignment.valid?).to eq true
        result = bulk_assignment.process
        expect(Task.count).to eq 4
        expect(result.count).to eq 2
        expect(result.first.assigned_to).to eq assigned_to
        expect(result.first.type).to eq "NoShowHearingTask"
        expect(result.first.assigned_by).to eq assigned_by
        expect(result.first.appeal).to eq schedule_hearing1.appeal
        expect(result.first.parent_id).to eq schedule_hearing1.id
      end
    end
  end
end