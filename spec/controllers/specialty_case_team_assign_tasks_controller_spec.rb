# frozen_string_literal: true

RSpec.describe SpecialtyCaseTeamAssignTasksController, :all_dbs do
  describe "POST /specialty_case_team_assign_tasks" do
    let!(:attorney) { create(:user) }
    let!(:judge) { create(:user, :judge) }
    let!(:user) { create(:user) }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let!(:sct_tasks) do
      create_list(:specialty_case_team_assign_task, 3)
    end
    let!(:assignee) { attorney }
    let!(:params) do
      sct_tasks.map do |sct_task|
        {
          external_id: sct_task.appeal.external_id,
          parent_id: sct_task.id,
          assigned_to_id: assignee.id
        }
      end
    end

    before do
      User.authenticate!(user: user)
      judge.administered_judge_teams.first.add_user(attorney)
      judge.save
    end

    subject { post :create, params: { tasks: params } }

    context "when cases will be assigned to an attorney" do
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
          expect(review_task["attributes"]["assigned_by"]["pg_id"]).to eq user.id
          expect(judge_review_task.children.first.type).to eq AttorneyTask.name
          expect(judge_review_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        end

        assign_tasks = response_body.select { |task| task["attributes"]["type"].eql? SpecialtyCaseTeamAssignTask.name }
        expect(assign_tasks.count).to eq 3
        expect(assign_tasks.all? do |assign_task|
          assign_task["attributes"]["status"].eql? Constants.TASK_STATUSES.completed
        end).to eq true
      end

      context "when the assignment encounters an error" do
        before { create(:ama_judge_decision_review_task, assigned_to: judge, parent: sct_tasks.last.parent) }

        it "Returns an error and creates no tasks" do
          subject

          expect(response.status).to eq 400
          expect(SpecialtyCaseTeamAssignTask.active.count).to eq sct_tasks.count
          expect(JudgeDecisionReviewTask.open.count).to eq 1
          expect(AttorneyTask.open.count).to eq 0
        end
      end
    end
  end
end
