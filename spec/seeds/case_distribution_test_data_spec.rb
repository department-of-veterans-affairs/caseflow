# frozen_string_literal: true

describe Seeds::CaseDitributionTestData do
  let(:seed) { Seeds::CaseDitributionTestData.new }

  context "initial values" do
    it "are set properly for legacy inactive admin judge team file_number and participant id" do
      expect(seed.instance_variable_get(:@legacy_inactive_admin_judge_team_file_number)).to eq 703_000_200
      expect(seed.instance_variable_get(:@legacy_inactive_admin_judge_team_participant_id)).to eq 713_000_000
    end

    it "are set properly for direct review file number and participant id" do
      expect(seed.instance_variable_get(:@direct_review_file_number)).to eq 706_000_200
      expect(seed.instance_variable_get(:@direct_review_participant_id)).to eq 716_000_000
    end

    it "are set properly for ama hearing held file number and participant id" do
      expect(seed.instance_variable_get(:@ama_hearing_held_file_number)).to eq 709_000_200
      expect(seed.instance_variable_get(:@ama_hearing_held_participant_id)).to eq 719_000_000
    end
  end

  context "#seed!" do
    it "creates test data for case distribution" do
      seed.seed!

      #checking CaseDistributionlevers count
      expect( CaseDistributionLever.count).to eq 20

      expect(Appeal.where(docket_type: "direct_review").count).to eq 38
      expect(Appeal.where(docket_type: "direct_review").first.receipt_date).to eq Date.strptime("01/21/2004","%m/%d/%Y")

      expect(Appeal.where(docket_type: "hearing").count).to eq 35
      expect(Appeal.where(docket_type: "hearing").first.receipt_date).to eq Date.strptime("01/19/2004","%m/%d/%Y")

      expect(AppealState.where(appeal_type: "Appeal").count).to eq 73
      expect(Claimant.count).to eq 73

      expect(LegacyAppeal.where(closest_regional_office: "RO17").count).to eq 35

      expect(User.count).to eq 48
      expect(User.find_by_css_id("BVAABSHIRE").full_name).to eq "BVA Judge Abshire"
      expect(User.find_by_css_id("BVAREDMAN").full_name).to eq "BVA Judge Redman"
      expect(User.find_by_css_id("BVABECKER").full_name).to eq "BVA Judge Becker"

      #creates data for missing tester judges data
      expect(User.find_by_css_id("BVAKEELING").full_name).to eq "BVA Judge Keeling"
      expect(User.find_by_css_id("BVACOTBJ").full_name).to eq "BVA ChairOfThe BoardJudge"

      expect(Veteran.where(first_name: "Bob").first.file_number).to eq "709000201"
      expect(Veteran.where(first_name: "Bob").first.participant_id).to eq "719000001"
      expect(Veteran.count).to eq 108
    end
  end
end

