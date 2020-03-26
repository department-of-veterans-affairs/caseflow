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

        expect(response).to be_successful
      end
    end
  end

  describe "#return_to_lit_support", :postgres do
    context "when the motion is valid" do
      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models
        params = { task_id: task.id }
        post :return_to_lit_support, params: params

        expect(response).to be_successful
        task.reload
        expect(task.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end

  describe "#return_to_judge", :postgres do
    context "when the motion is valid" do
      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_on_vacate_stream
        params = { task_id: task.id, instructions: "instructions" }
        User.stub = task.assigned_to
        post :return_to_judge, params: params

        expect(response).to be_successful
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

  def create_task_on_vacate_stream
    appeal = create(:appeal, :with_straight_vacate_stream)
    vacate_stream = Appeal.vacate.find_by(stream_docket_number: appeal.docket_number)
    AttorneyTask.find_by(appeal: vacate_stream)
  end
end
