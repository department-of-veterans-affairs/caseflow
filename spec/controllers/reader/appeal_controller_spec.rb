RSpec.describe Reader::AppealController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:vacols_record) { :remand_decided }
  let(:appeal) { Generators::Appeal.build(vbms_id: "123456789S", vacols_record: vacols_record) }

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
        expect(issue[:description]).to eq hashed_issue[index].description
        expect(issue[:type][:name]).to eq hashed_issue[index].type[:name].to_s
        expect(issue[:type][:label]).to eq hashed_issue[index].type[:label]
        expect(issue[:vacols_sequence_id]).to eq hashed_issue[index].vacols_sequence_id
      end

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
