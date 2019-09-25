# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe PostDecisionMotionsController do
  let(:user) { create(:default_user) }

  before do
    User.authenticate!(roles: ["System Admin"])
    User.stub = user
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

    context "when the motion is valid" do
      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models
        assigned_to = create(:user)

        params =
          { disposition: "granted",
            task_id: task.id,
            vacate_type: "straight_vacate_and_readjudication",
            instructions: "formatted instructions",
            assigned_to_id: assigned_to.id }
        post :create, params: params

        expect(response).to be_success
        expect(flash[:success]).to be_present
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
      assigned_to: user,
      assigned_by: assigned_by
    )
  end
end
