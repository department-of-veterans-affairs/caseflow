# frozen_string_literal: true

describe CaseDistributionIneligibleJudges, :postgres do
  describe ".ineligible_vacols_judges" do
    context "when inactive staff exists" do
      let!(:inactive_staff) { create(:staff, sactive: "I") }
      let!(:active_staff) { create(:staff) }

      it "returns ineligible vacols judges" do
        result = described_class.ineligible_vacols_judges

        expect(result.size).to eq(1)
        expect(result.first[:sdomainid]).to eq(inactive_staff.sdomainid)
        expect(result.first[:sdomainid]).not_to eq(active_staff.sdomainid)
      end
    end

    context "when active staff exists" do
      before { create(:staff) }

      it "returns empty array" do
        result = described_class.ineligible_vacols_judges

        expect(result.size).to eq(0)
        expect(result).to eq([])
      end
    end
  end

  describe ".ineligible_caseflow_judges" do
    context "when user status is inactive" do
      let!(:inactive_user) { create(:user, status: "inactive") }

      it "return ineligible caseflow judges" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(1)
        expect(result.first[:css_id]).to eq(inactive_user.css_id)
      end
    end

    context "when organization is Judge Team and status is inactive" do
      let!(:user) { create(:user) }
      let!(:organization) { create(:judge_team, status: "inactive") }
      let!(:organizations_user) { create(:organizations_user, :admin, organization: organization, user: user) }

      it "return ineligible caseflow judges" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(1)
        expect(result.first[:css_id]).to eq(user.css_id)
      end
    end

    context "when user status is active" do
      let!(:inactive_user) { create(:user) }

      it "return an empty array" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(0)
        expect(result).to eq([])
      end
    end

    context "when organization is Judge Team and status is active" do
      let!(:user) { create(:user) }
      let!(:organization) { create(:judge_team) }
      let!(:organizations_user) { create(:organizations_user, :admin, organization: organization, user: user) }

      it "return ineligible caseflow judges" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(0)
        expect(result).to eq([])
      end
    end
  end

  describe ".non_admin_users_of_judge_teams" do
    context "when Judge Team is admin" do
      let!(:user) { create(:user) }
      let!(:organization) { create(:judge_team) }
      let!(:organizations_user) { create(:organizations_user, :admin, organization: organization, user: user) }

      it "returns an empty array" do
        result = described_class.non_admin_users_of_judge_teams

        expect(result).to eq([])
      end
    end

    context "when Judge Team is non admin" do
      let!(:user) { create(:user) }
      let!(:organization) { create(:judge_team) }
      let!(:organizations_user) { create(:organizations_user, organization: organization, user: user) }

      it "returns an array" do
        result = described_class.non_admin_users_of_judge_teams

        expect(result.size).to eq(1)
        expect(result).to eq([user.id])
      end
    end
  end
end
