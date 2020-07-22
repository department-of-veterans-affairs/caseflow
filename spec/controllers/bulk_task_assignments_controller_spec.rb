# frozen_string_literal: true

RSpec.describe BulkTaskAssignmentsController, :postgres, type: :controller do
  describe "#create" do
    let(:organization) { HearingsManagement.singleton }
    let!(:schedule_hearing1) do
      create(
        task_type.name.underscore.to_sym,
        assigned_to: organization,
        created_at: 5.days.ago
      )
    end
    let!(:schedule_hearing2) do
      create(task_type.name.underscore.to_sym,
             assigned_to: organization,
             created_at: 2.days.ago)
    end

    let(:assigned_to) { create(:user) }
    let(:assigned_by) { create(:user) }

    let(:params) do
      {
        assigned_to_id: assigned_to.id,
        organization_url: organization.url,
        task_type: task_type.name,
        task_count: task_count
      }
    end
    let(:task_type) { NoShowHearingTask }
    let(:task_count) { 2 }

    before { User.authenticate!(user: assigned_by) }
    after { User.unauthenticate! }

    context "when user has access to the org" do
      shared_examples "valid bulk assign" do
        it "should return tasks" do
          get :create, params: { bulk_task_assignment: params }
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)
          expect(response_body["queue_config"]["tabs"][0]["tasks"].count).to eq 0
          expect(response_body["queue_config"]["tabs"][1]["tasks"].count).to eq 2
          expect(response_body["queue_config"]["tabs"][2]["tasks"].count).to eq 0
          expect(response_body["queue_config"]["tabs"][3]["tasks"].count).to eq 0
        end
      end

      before do
        organization.users << assigned_to
        OrganizationsUser.make_user_admin(assigned_by, organization)
      end

      it_behaves_like "valid bulk assign"

      context "when the user is a vso" do
        before { assigned_by.update!(roles: ["VSO"]) }

        it "should not return tasks because the task type is invalid for VSOs" do
          get :create, params: { bulk_task_assignment: params }
          expect(response.status).to eq 403
          expect(JSON.parse(response.body)["errors"].first["title"]).to eq "VSOs cannot create that task."
        end

        context "when the task type is valid for VSOs" do
          let(:task_type) { InformalHearingPresentationTask }

          it_behaves_like "valid bulk assign"
        end
      end
    end

    context "when user does not have access to the org" do
      it "should not return tasks" do
        get :create, params: { bulk_task_assignment: params }
        expect(response.status).to eq 400
        expect(JSON.parse(response.body)["errors"].first["title"]).to eq "Record is invalid"
      end
    end
  end
end
