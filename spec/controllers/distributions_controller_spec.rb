# frozen_string_literal: true

describe DistributionsController, :all_dbs do
  before { create(:case_distribution_lever, :request_more_cases_minimum) }

  describe "#new" do
    let(:user) { create(:user) }

    subject { get :new, params: { user_id: user.id } }

    before { User.authenticate!(user: user) }

    context "provided user is not a judge" do
      it "renders an error" do
        subject

        body = JSON.parse(response.body)
        expect(body["errors"].first["error"]).to eq "not_judge"
      end
    end

    context "there is a pending distribution" do
      it "returns the pending distribution and no more were created" do
        create(:staff, :judge_role, sdomainid: user.css_id)

        distribution = Distribution.create!(judge: user, status: "pending")
        number_of_distributions = Distribution.count
        subject

        body = JSON.parse(response.body)
        expect(body["distribution"]["id"]).to eq distribution.id
        expect(body["distribution"]["status"]).to eq "pending"
        expect(Distribution.count).to eq number_of_distributions
      end
    end

    context "provided user is a judge" do
      before { create(:staff, :judge_role, sdomainid: user.css_id) }

      it "renders the created distribution as json" do
        subject

        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["distribution"].keys).to match_array(%w[id created_at updated_at status distributed_cases_count])
      end

      context "but is not the logged in user" do
        let(:authed_user) { create(:user) }

        before { User.authenticate!(user: authed_user) }

        it "returns an error" do
          subject

          body = JSON.parse(response.body)
          expect(body["errors"].first["title"]).to eq "Cannot request cases for another judge"
        end

        context "but scm is enabled" do
          before { SpecialCaseMovementTeam.singleton.add_user(authed_user) }

          it "renders the created distribution as json" do
            subject

            expect(response.status).to eq 200
            body = JSON.parse(response.body)
            expect(body["errors"]).to eq nil
            expect(body["distribution"].keys).to match_array(
              %w[id created_at updated_at status distributed_cases_count]
            )
          end
        end
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
