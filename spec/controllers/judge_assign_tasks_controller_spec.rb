# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.describe JudgeAssignTasksController, :vacols do
  describe "POST /judge_assign_tasks" do
    context "when cases will be assigned to an attorney" do
      let!(:attorney) { create(:user) }
      let!(:judge) { create(:user) }
      let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
      let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }

      let!(:assign_tasks) { create_list(:ama_judge_task, 3, assigned_to: judge, parent: create(:root_task)) }
      let!(:params) do
        assign_tasks.map do |assign_task|
          {
            external_id: assign_task.appeal.external_id,
            parent_id: assign_task.id,
            assigned_to_id: attorney.id
          }
        end
      end

      before { User.authenticate!(user: judge) }

      subject { post :create, params: { tasks: params } }

      it "returns the newly created tasks along with their new parents and old parents" do
        subject

        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.count).to eq 9

        attorney_tasks = response_body.select { |task| task["attributes"]["type"].eql? AttorneyTask.name }
        expect(attorney_tasks.count).to eq 3
        attorney_tasks.each do |attorney_task|
          expect(attorney_task["attributes"]["assigned_to"]["id"]).to eq attorney.id
          expect(attorney_task["attributes"]["assigned_by"]["pg_id"]).to eq judge.id
          expect(attorney_task["attributes"]["status"]).to eq Constants.TASK_STATUSES.assigned
          expect(AttorneyTask.find(attorney_task["id"]).parent.type).to eq JudgeDecisionReviewTask.name
        end

        review_tasks = response_body.select { |task| task["attributes"]["type"].eql? JudgeDecisionReviewTask.name }
        expect(review_tasks.count).to eq 3
        review_tasks.each do |review_task|
          judge_review_task = JudgeDecisionReviewTask.find(review_task["id"])
          expect(review_task["attributes"]["assigned_to"]["id"]).to eq judge.id
          expect(judge_review_task.children.first.type).to eq AttorneyTask.name
          expect(judge_review_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        end

        assign_tasks = response_body.select { |task| task["attributes"]["type"].eql? JudgeAssignTask.name }
        expect(assign_tasks.count).to eq 3
        expect(assign_tasks.all? do |assign_task|
          assign_task["attributes"]["status"].eql? Constants.TASK_STATUSES.completed
        end).to eq true
      end
    end
  end
end
