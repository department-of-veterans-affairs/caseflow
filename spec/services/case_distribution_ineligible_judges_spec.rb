# frozen_string_literal: true

describe CaseDistributionIneligibleJudges, :postgres do
  describe ".ineligible_vacols_judges" do
    context "when inactive staff exists" do
      let!(:active_non_judge_staff) { create(:staff) }
      let!(:inactive_non_judge_staff) { create(:staff, :inactive) }
      let!(:active_judge_staff) { create(:staff, :judge_role) }
      let!(:inactive_judge_staff) { create(:staff, :judge_role, :inactive) }
      let!(:non_judge_with_sattyid) { create(:staff, sattyid: 9999) }
      let!(:attorney_judge_staff) { create(:staff, :attorney_judge_role) }

      it "returns ineligible vacols judges" do
        result = described_class.ineligible_vacols_judges
        eligible_vacols_judges = [active_judge_staff.sdomainid, attorney_judge_staff.sdomainid]


        #expect(result.size).to eq(2)
        expect(result).to contain_exactly(
          {:sattyid=>"4", :sdomainid=>"BVA4", :svlj=>"J"},
          {:sattyid=>"9999", :sdomainid=>"BVA5", :svlj=>nil}
        )
      end
    end
  end

  describe ".ineligible_caseflow_judges" do
    context "when caseflow users are exists" do
      let!(:inactive_user) { create(:user, :inactive) }
      let!(:active_user) { create(:user, :judge) }

      it "returns ineligible caseflow judges but not active judges" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(1)
        expect(result.first[:css_id]).to eq(inactive_user.css_id)
        expect(result.first[:css_id]).not_to eq(active_user.css_id)
      end
    end

    context "when caseflow users are tied to judge team organizations" do
      let!(:active_judge_user) { create(:user, :judge) }
      let!(:inactive_judge_user) { create(:user, :judge) }
      before { inactive_judge_user.organizations.last.update(status: 'inactive') }

      it "returns ineligible judge team users but not eligible judge team users" do
        result = described_class.ineligible_caseflow_judges

        expect(result.size).to eq(1)
        expect(result.first[:css_id]).to eq(inactive_judge_user.css_id)
        expect(result.first[:css_id]).not_to eq(active_judge_user.css_id)
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
