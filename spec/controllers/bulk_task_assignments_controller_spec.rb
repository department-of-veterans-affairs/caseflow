# frozen_string_literal: true

RSpec.describe BulkTaskAssignmentsController, :postgres, type: :controller do
  describe "#create" do
    let(:organization) { HearingsManagement.singleton }
    let!(:schedule_hearing1) do
      create(
        :no_show_hearing_task,
        assigned_to: organization,
        created_at: 5.days.ago
      )
    end
    let!(:schedule_hearing2) do
      create(:no_show_hearing_task,
             assigned_to: organization,
             created_at: 2.days.ago)
    end

    let(:assigned_to) { create(:user) }
    let(:assigned_by) { create(:user) }

    let(:params) do
      {
        assigned_to_id: assigned_to.id,
        organization_url: organization.url,
        task_type: task_type,
        task_count: task_count
      }
    end
    let(:task_type) { "NoShowHearingTask" }
    let(:task_count) { 2 }

    context "when user has access" do
      before { User.authenticate!(user: assigned_by) }
      after { User.unauthenticate! }

      it "should return tasks" do
        organization.users << assigned_to
        organization.users << assigned_by
        get :create, params: { bulk_task_assignment: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["data"].size).to eq 2
      end
    end

    context "when user does not have access" do
      before { User.authenticate!(user: assigned_by) }
      after { User.unauthenticate! }

      it "should return tasks" do
        get :create, params: { bulk_task_assignment: params }
        expect(response.status).to eq 400
        expect(JSON.parse(response.body)["errors"].first["title"]).to eq "Record is invalid"
      end
    end
  end
end
