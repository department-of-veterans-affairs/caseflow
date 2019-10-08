# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe DistributionsController, :all_dbs do
  describe "#new" do
    context "current user is not a judge" do
      it "renders an error" do
        User.authenticate!(user: create(:user))
        get :new

        body = JSON.parse(response.body)
        expect(body["errors"].first["error"]).to eq "not_judge"
      end
    end

    context "there is a pending distribution" do
      it "returns the pending distribution and no more were created" do
        judge = create(:user)
        create(:staff, :judge_role, sdomainid: judge.css_id)
        User.authenticate!(user: judge)

        distribution = Distribution.create!(judge: judge, status: "pending")
        number_of_distributions = Distribution.count

        get :new

        body = JSON.parse(response.body)
        expect(body["distribution"]["id"]).to eq distribution.id
        expect(body["distribution"]["status"]).to eq "pending"
        expect(Distribution.count).to eq number_of_distributions
      end
    end

    context "current user is a judge" do
      it "renders the created distribution as json" do
        judge = create(:user)
        create(:staff, :judge_role, sdomainid: judge.css_id)
        User.authenticate!(user: judge)
        get :new

        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["distribution"].keys).to match_array(%w[id created_at updated_at status distributed_cases_count])
      end
    end
  end

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
