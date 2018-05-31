RSpec.describe Reader::AppealController, type: :controller do
  before do
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:case_issues) do
    [
      create(:case_issue),
      create(:case_issue)
    ]
  end
  let(:vacols_case) do
    create(
      :case,
      :has_regional_office,
      :type_original,
      :aod,
      case_issues: case_issues,
      folder: create(:folder, tinum: "docket-number"),
      correspondent: create(:correspondent, snamef: "first", snamemi: "m", snamel: "last")
    )
  end
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  describe "GET fetch appeal by VBMS Id" do
    it "should be successful" do
      request.env["HTTP_VETERAN_ID"] = appeal[:vbms_id]
      get :find_appeals_by_veteran_id

      expect(response.status).to eq 200
      hashed_appeal = appeal.to_hash(issues: appeal.issues)
      response_body = JSON.parse(response.body)["appeals"]

      appeal_response = response_body[0].deep_symbolize_keys
      hashed_issue = hashed_appeal["issues"]

      expect(appeal_response[:vacols_id]).to eq hashed_appeal["vacols_id"]
      expect(appeal_response[:vbms_id]).to eq hashed_appeal["vbms_id"]
      appeal_response[:issues].each_with_index do |issue, index|
        expect(issue[:description]).to eq hashed_issue[index][:description]
        expect(issue[:type]).to eq hashed_issue[index][:type]
        expect(issue[:vacols_sequence_id]).to eq hashed_issue[index][:vacols_sequence_id]
        expect(issue[:id]).to eq hashed_issue[index][:id]
      end
      expect(appeal_response[:veteran_first_name]).to eq hashed_appeal["veteran_first_name"]
      expect(appeal_response[:veteran_last_name]).to eq hashed_appeal["veteran_last_name"]
      expect(appeal_response[:veteran_full_name]).to eq hashed_appeal["veteran_full_name"]
      expect(appeal_response[:docket_number]).to eq hashed_appeal["docket_number"]
      expect(appeal_response[:regional_office]).to eq hashed_appeal["regional_office"]
      expect(appeal_response[:aod]).to eq hashed_appeal["aod"]
      expect(appeal_response[:cavc]).to eq hashed_appeal["cavc"]
      expect(appeal_response[:type]).to eq hashed_appeal["type"]
    end

    it "should return not found" do
      request.env["HTTP_VETERAN_ID"] = "doesnotexist!"
      get :find_appeals_by_veteran_id
      expect(response.status).to eq 404
    end
  end
end
