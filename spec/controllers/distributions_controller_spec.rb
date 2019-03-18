# frozen_string_literal: true

require "rails_helper"

describe DistributionsController do
  describe "#show" do
    context "current user is not judge associated with distribution" do
      it "renders an error" do
        judge = create(:user)
        create(:staff, :judge_role, sdomainid: judge.css_id)
        distribution = Distribution.create!(judge: judge)

        User.authenticate!(roles: ["System Admin"])
        get :show, params: { id: distribution.id }

        body = JSON.parse(response.body)
        expect(body["errors"].first["error"]).to eq "different_user"
      end
    end

    context "distribution status is error" do
      it "renders an error" do
        judge = create(:user)
        create(:staff, :judge_role, sdomainid: judge.css_id)
        distribution = Distribution.create!(judge: judge)
        distribution.update!(status: "error")

        User.authenticate!(user: judge)
        get :show, params: { id: distribution.id }

        body = JSON.parse(response.body)
        expect(body["errors"].first["error"]).to eq "distribution_error"
      end
    end

    context "distribution is valid and current user is authorized to access it" do
      it "renders the distribution as json" do
        judge = create(:user)
        create(:staff, :judge_role, sdomainid: judge.css_id)
        distribution = Distribution.create!(judge: judge)

        User.authenticate!(user: judge)
        get :show, params: { id: distribution.id }

        body = JSON.parse(response.body)
        expect(body["distribution"]["id"]).to eq distribution.id
        expect(body["distribution"].keys).to match_array(%w[id created_at updated_at status distributed_cases_count])
      end
    end
  end
end
