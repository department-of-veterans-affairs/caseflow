# frozen_string_literal: true

describe PostDecisionMotionsController do
  let(:user) { create(:default_user) }
  let(:judge) { create(:user) }
  let(:judge_team) { JudgeTeam.create_for_judge(judge) }

  let(:post_decision_motion) { create(:post_decision_motion) }

  before do
    User.authenticate!(roles: ["System Admin"])
    User.stub = judge
  end

  describe "#create", :postgres do
    context "when the motion is invalid" do
      it "returns an error" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        post :create, params: { disposition: "granted" }
        expect(response.status).to eq 404
      end

      it "returns an error" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models
        post :create, params: { disposition: "granted", task_id: task.id }

        body = JSON.parse(response.body)

        expect(body["errors"]).to match_array(["detail" => "Vacate type is required for granted disposition"])
      end
    end

    context "when there is no judge or attorney team" do
      it "returns an error" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models
        assigned_to = user

        params =
          { disposition: "granted",
            task_id: task.id,
            vacate_type: "vacate_and_readjudication",
            instructions: "formatted instructions",
            assigned_to_id: assigned_to.id }

        post :create, params: params

        body = JSON.parse(response.body)
        expect(body["errors"]).to match_array(
          [{ "detail" => "Assigned by has to be a judge, Assigned to has to be an attorney" }]
        )
      end
    end

    context "when the motion is valid" do
      let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
      before do
        allow(judge).to receive(:judge_in_vacols?).and_return(true)
        allow_any_instance_of(PostDecisionMotionUpdater).to receive(:judge_user).and_return(judge)
      end

      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models

        expect(task.assigned_to).to eq judge

        judge_team.add_user(user)

        params =
          { disposition: "granted",
            task_id: task.id,
            vacate_type: "vacate_and_readjudication",
            instructions: "formatted instructions",
            assigned_to_id: user.id }
        post :create, params: params

        expect(response).to be_success
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "#create_issues" do
    context "with a valid PostDecisionMotion id" do
      it "returns a 200 response and creates issues" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        create_task_without_unnecessary_models
        judge_team.add_user(user)

        appeal = post_decision_motion.task.appeal.reload

        expect(appeal.decision_issues.size).to eq(3)

        post :create_issues, params: { id: post_decision_motion.id }

        appeal.reload

        expect(response).to be_success
        expect(appeal.request_issues.size).to eq(3)
        expect(appeal.decision_issues.size).to eq(6)
      end
    end

    context "with an invalid PostDecisionMotion id" do
      it "returns a 404 response and doesn't create issues" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        create_task_without_unnecessary_models
        judge_team.add_user(user)

        appeal = post_decision_motion.task.appeal.reload

        expect(appeal.decision_issues.size).to eq(3)
        expect(appeal.request_issues.size).to eq(3)

        post :create_issues, params: { id: 9999 }

        appeal.reload

        expect(response.status).to eq 404
        expect(appeal.request_issues.size).to eq(3)
        expect(appeal.decision_issues.size).to eq(3)
      end
    end
  end

  def create_task_without_unnecessary_models
    appeal = create(:appeal)
    assigned_by = create(:user)
    parent = create(:root_task, appeal: appeal)
    create(
      :judge_address_motion_to_vacate_task,
      appeal: appeal,
      parent: parent,
      assigned_to: judge,
      assigned_by: assigned_by
    )
  end
end
