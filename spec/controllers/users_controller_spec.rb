# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.describe UsersController, :vacols, type: :controller do
  let!(:user) { User.authenticate!(roles: ["System Admin"]) }
  let!(:staff) { create(:staff, :attorney_judge_role, user: user) }

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }
    let!(:attorneys) { create_list(:staff, 2, :attorney_role) }

    context "when role is passed" do
      it "should return a list of only judges" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq 3
      end
    end

    context "when role is not passed" do
      it "should return an empty hash" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body).to eq({})
      end
    end
  end

  describe "GET /users?role=Attorney" do
    let(:judge) { Judge.new(FactoryBot.create(:user)) }
    let!(:judge_team) { JudgeTeam.create_for_judge(judge.user) }
    let(:team_member_count) { 3 }
    let(:solo_count) { 3 }
    let(:team_attorneys) { FactoryBot.create_list(:user, team_member_count) }
    let(:solo_attorneys) { FactoryBot.create_list(:user, solo_count) }

    before do
      create(:staff, :judge_role, user: judge.user)

      [team_attorneys, solo_attorneys].flatten.each do |attorney|
        create(:staff, :attorney_role, user: attorney)
      end

      team_attorneys.each do |attorney|
        OrganizationsUser.add_user_to_organization(attorney, judge_team)
      end
    end

    context "when judge ID is passed" do
      subject { get :index, params: { role: "Attorney", judge_id: judge.user.id } }

      it "should return a list of attorneys on the judge's team" do
        subject
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq team_member_count
      end
    end

    context "when judge ID is not passed" do
      subject { get :index, params: { role: "Attorney" } }

      it "should return a list of all attorneys and judges" do
        subject
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorneys"].size).to eq team_member_count + solo_count + 2
      end
    end
  end

  describe "GET /users?role=HearingCoordinator" do
    let!(:coordinators) { create_list(:staff, 3, :hearing_coordinator) }

    context "when role is passed" do
      it "should return a list of hearing coordinators" do
        get :index, params: { role: "HearingCoordinator" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["coordinators"].size).to eq 3
      end
    end
  end

  describe "GET /users?role=Judge" do
    let!(:judges) { create_list(:staff, 2, :judge_role) }

    context "when role is passed" do
      it "should return a list of judges" do
        get :index, params: { role: "Judge" }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["judges"].size).to eq 3
      end
    end
  end

  describe "GET /users?role=non_judges" do
    before { judge_team_count.times { JudgeTeam.create_for_judge(FactoryBot.create(:user)) } }

    context "when there are no judge teams" do
      let!(:users) { FactoryBot.create_list(:user, 8) }
      let(:judge_team_count) { 0 }

      # Add one for the current user who was created outside the scope of this test.
      let(:user_count) { users.count + 1 }

      it "returns all of the users in the database" do
        get(:index, params: { role: "non_judges" })

        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)
        expect(response_body["non_judges"]["data"].size).to eq(user_count)
      end
    end
  end
end
