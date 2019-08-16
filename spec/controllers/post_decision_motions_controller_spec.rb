# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe PostDecisionMotionsController do
  describe "#create", :postgres do
    context "when the motion is invalid" do
      it "returns an error" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        post :create, params: { post_decision_motion: { disposition: "granted" } }

        body = JSON.parse(response.body)

        expect(body["errors"]).to match_array(["detail" => "Task must exist"])
      end
    end

    context "when the motion is valid" do
      it "returns a 200 response" do
        allow(controller).to receive(:verify_authentication).and_return(true)

        task = create_task_without_unnecessary_models

        post :create, params: { post_decision_motion: { disposition: "granted", task_id: task.id } }

        expect(response).to be_success
        expect(flash[:success]).to be_present
      end
    end
  end

  def create_task_without_unnecessary_models
    appeal = build_stubbed(:appeal)
    assigned_by = build_stubbed(:user)
    assigned_to = build_stubbed(:user)
    parent = build_stubbed(:root_task, assigned_to: assigned_to)
    allow(parent).to receive(:when_child_task_created).and_return(true)
    create(
      :vacate_motion_mail_task,
      appeal: appeal,
      parent: parent,
      assigned_to: assigned_to,
      assigned_by: assigned_by
    )
  end
end
