# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe PostDecisionMotionsController do
  describe "#create", :postgres do
    context "when the motion is invalid" do
      it "returns an error" do
        User.authenticate!(roles: ["System Admin"])
        post :create, params: { post_decision_motion: { disposition: "granted" } }

        body = JSON.parse(response.body)

        expect(body["errors"]).to match_array(["detail" => "Task must exist"])
      end
    end

    context "when the motion is valid" do
      it "returns a 200 response" do
        task = create(:vacate_motion_mail_task)
        User.authenticate!(roles: ["System Admin"])
        post :create, params: { post_decision_motion: { disposition: "granted", task_id: task.id } }

        expect(response).to be_success
        expect(flash[:success]).to be_present
      end
    end
  end
end
