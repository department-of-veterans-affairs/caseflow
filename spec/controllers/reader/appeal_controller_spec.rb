RSpec.describe Reader::AppealController, type: :controller do
  before do
    FeatureToggle.enable!(:reader)
  end

  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:vacols_record) { :remand_decided }
  let(:appeal) { Generators::Appeal.build(vbms_id: "123456789S", vacols_record: vacols_record) }
  describe "GET fetch appeal by VBMS Id" do
    it "should be succesful" do
      request.headers["HTTP_VETERAN_ID"] = appeal[:vbms_id]
      get :find_appeals_by_veteran_id

      expect(response.status).to eq 200
      hashed_appeal = appeal.to_hash(issues: appeal.issues)
      response_body = JSON.parse(response.body)["appeals"]

      appeal_response = response_body[0].deep_symbolize_keys
      hashed_issue = hashed_appeal["issues"]

      expect(appeal_response[:vacols_id]).to eq hashed_appeal["vacols_id"]
      expect(appeal_response[:vbms_id]).to eq hashed_appeal["vbms_id"]

      appeal_response[:issues].each_with_index do |issue, index|
        expect(issue[:id]).to eq hashed_issue[index][:id]
        expect(issue[:allow]).to eq hashed_issue[index][:allow]
        expect(issue[:deny]).to eq hashed_issue[index][:deny]
        expect(issue[:remand]).to eq hashed_issue[index][:remand]
        expect(issue[:description]).to eq hashed_issue[index].description
        expect(issue[:type][:name]).to eq hashed_issue[index].type[:name].to_s
        expect(issue[:type][:label]).to eq hashed_issue[index].type[:label]
        expect(issue[:vacols_sequence_id]).to eq hashed_issue[index][:vacols_sequence_id]
        expect(issue[:hearing_worksheet_reopen]).to eq hashed_issue[index][:hearing_worksheet_reopen]
        expect(issue[:hearing_worksheet_vha]).to eq hashed_issue[index][:hearing_worksheet_vha]
      end

      expect(appeal_response[:docket_number]).to eq hashed_appeal["docket_number"]
      expect(appeal_response[:regional_office]).to eq hashed_appeal["regional_office"]
      expect(appeal_response[:aod]).to eq hashed_appeal["aod"]
      expect(appeal_response[:cavc]).to eq hashed_appeal["cavc"]
      expect(appeal_response[:type]).to eq hashed_appeal["type"]
    end

    it "fails routing validation" do
      request.headers["HTTP_VETERAN_ID"] = "03023232S!"
      expect { get :find_appeals_by_veteran_id }
        .to raise_error(ActionController::UrlGenerationError)
      expect { get :find_appeals_by_veteran_id, veteran_id: nil }.to raise_error(ActionController::UrlGenerationError)
      expect { get :find_appeals_by_veteran_id, veteran_id: "2" }.to raise_error(ActionController::UrlGenerationError)
      expect { get :find_appeals_by_veteran_id, veteran_id: "221121212121212" }
        .to raise_error(ActionController::UrlGenerationError)
    end

    it "should return not found" do
      request.headers["HTTP_VETERAN_ID"] = "doesnotexist!"
      get :find_appeals_by_veteran_id
      expect(response.status).to eq 404
    end
  end
end
