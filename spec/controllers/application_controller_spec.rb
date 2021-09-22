# frozen_string_literal: true

describe ApplicationController, type: :controller do
  let(:user) { build(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "#feedback" do
    def all_users_can_access_feedback
      get :feedback

      expect(response.status).to eq 200
    end

    it "allows users to see feedback page" do
      all_users_can_access_feedback
    end

    context "user is part of VSO" do
      before do
        allow(user).to receive(:vso_employee?) { true }
      end

      it "allows VSO user to see feedback page" do
        all_users_can_access_feedback
      end
    end
  end

  describe "no cache headers" do
    controller(ApplicationController) do
      def index
        render json: { hello: "world" }, status: :ok
      end
    end

    context "when toggle not set" do
      it "does not set Cache-Control" do
        get :index

        expect(response.headers["Cache-Control"]).to be_nil
      end
    end

    context "when toggle set" do
      before do
        FeatureToggle.enable!(:set_no_cache_headers)
      end

      after do
        FeatureToggle.disable!(:set_no_cache_headers)
      end

      it "sets Cache-Control etc" do
        get :index

        expect(response.headers["Cache-Control"]).to eq "no-cache, no-store"
      end
    end
  end

  describe "error handling v2" do
    context "when a MultipleOpenTasksOfSameTypeError error is raised" do
      subject { fail Caseflow::Error::MultipleOpenTasksOfSameTypeError, task_type: "JudgeDecisionReviewTask" }

      it "reports to sentry that the error is not actionable" do
        expect { subject }.to raise_error(Caseflow::Error::MultipleOpenTasksOfSameTypeError) do |_err|
          expect(Raven).to receive(:capture_exception).with(anything, extra: { error_uuid: anything, actionable: false })
        end
      end
    end
  end

  describe "error handling" do
    let!(:attorney) { create(:user) }
    let!(:judge) { create(:user) }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
    let!(:assign_task) { create(:ama_judge_assign_task, assigned_to: judge, parent: create(:root_task)) }
    let!(:assignee) { attorney }
    let!(:params) do
      { external_id: assign_task.appeal.external_id, parent_id: assign_task.id,
        assigned_to_id: assignee.id }
    end
    # TODO: figure out how to post to the judge_assign_tasks_controller create action
    # subject { post "/judge_assign_tasks", to: "judge_assign_tasks#create", as: :create }
    subject { post "/judge_assign_tasks", :controller=>"judge_assign_tasks", as: :create, params: { tasks: params } }
    # subject { post :create, params: { tasks: params } }

    before do
      User.authenticate!(user: judge)
      judge_decision_review_task = double(JudgeDecisionReviewTask)
      allow(judge_decision_review_task).to(
        receive(:create!).and_raise(Caseflow::Error::MultipleOpenTasksOfSameTypeError)
      )
    end

    context "when an appeal has more than one open active task of the same type" do
      it "reports the error as non-actionable to Sentry" do
        subject
        expect(Raven).to receive(:capture_exception).with(anything, extra: { error_uuid: anything, actionable: false })
      end
    end
  end
end
