# frozen_string_literal: true

describe CaseDistributionIneligibleJudges, :postgres do
  describe "ineligible vacols judges" do
    context "when inactive staff exists" do
      let!(:active_non_judge_staff) { create(:staff) }
      let!(:inactive_non_judge_staff) { create(:staff, :inactive) }
      let!(:active_judge_staff) { create(:staff, :judge_role) }
      let!(:inactive_judge_staff) { create(:staff, :judge_role, :inactive) }
      let!(:non_judge_with_sattyid) { create(:staff, sattyid: 9999) }
      let!(:attorney_judge_staff) { create(:staff, :attorney_judge_role) }
      # The associated caseflow user record needs to be ACTIVE with an inactive staff record
      let!(:inactive_judge_caseflow_record) { create(:user, :judge, css_id: inactive_judge_staff.sdomainid) }

      it ".ineligible_vacols_judges returns correct records" do
        result = described_class.ineligible_vacols_judges

        expect(result).to contain_exactly(
          { sattyid: inactive_judge_staff.sattyid,
            sdomainid: inactive_judge_staff.sdomainid,
            svlj: inactive_judge_staff.svlj },
          { sattyid: non_judge_with_sattyid.sattyid,
            sdomainid: non_judge_with_sattyid.sdomainid,
            svlj: non_judge_with_sattyid.svlj }
        )
        expect(result.size).to eq(2)
      end

      it ".vacols_judges_with_caseflow_records combines records correctly" do
        result = described_class.vacols_judges_with_caseflow_records

        expect(result).to contain_exactly(
          { sattyid: inactive_judge_staff.sattyid,
            sdomainid: inactive_judge_staff.sdomainid,
            svlj: inactive_judge_staff.svlj,
            id: inactive_judge_caseflow_record.id,
            css_id: inactive_judge_caseflow_record.css_id },
          { sattyid: non_judge_with_sattyid.sattyid,
            sdomainid: non_judge_with_sattyid.sdomainid,
            svlj: non_judge_with_sattyid.svlj }
        )
        expect(result.size).to eq(2)
      end
    end
  end

  describe "ineligible caseflow judges" do
    context "when caseflow users are exists" do
      let!(:inactive_user) { create(:user, :inactive) }
      let!(:inactive_user_no_vacols_record) { create(:user, :inactive) }
      let!(:active_user) { create(:user) }
      # The associated staff record needs to be ACTIVE with an inactive caseflow user record
      let!(:inactive_user_vacols_record) { create(:staff, user: inactive_user) }

      it ".ineligible_caseflow_judges returns correct records" do
        result = described_class.ineligible_caseflow_judges

        expect(result).to contain_exactly(
          { id: inactive_user.id, css_id: inactive_user.css_id },
          { id: inactive_user_no_vacols_record.id, css_id: inactive_user_no_vacols_record.css_id }
        )
        expect(result).not_to include({ id: active_user.id, css_id: active_user.css_id })
        expect(result.size).to eq(2)
      end

      it ".caseflow_judges_with_vacols_records combines records correctly" do
        result = described_class.caseflow_judges_with_vacols_records

        expect(result).to contain_exactly(
          { id: inactive_user.id,
            css_id: inactive_user.css_id,
            sattyid: inactive_user_vacols_record.sattyid,
            sdomainid: inactive_user_vacols_record.sdomainid,
            svlj: inactive_user_vacols_record.svlj },
          { id: inactive_user_no_vacols_record.id,
            css_id: inactive_user_no_vacols_record.css_id }
        )
        expect(result.size).to eq(2)
      end
    end
  end
end
