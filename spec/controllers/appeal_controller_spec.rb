RSpec.describe Reader::AppealController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:vacols_record) { :remand_decided }  
  let(:appeal) { Generators::Appeal.build(vacols_record: vacols_record) }

  describe "GET fetch appeal by VBMS Id" do
    it "should be succesful" do
      get :find_appeals_by_veteran_id, veteran_id: appeal[:vbms_id]
      expect(response.status).to eq 200
      hashed_appeal = appeal.to_hash
      response_body = JSON.parse(response.body)

      expect(response_body["vacols_id"]).to eq hashed_appeal[:vacols_id]
      expect(response_body["vbms_id"]).to eq hashed_appeal[:vbms_id]
      expect(response_body["issues"]).to eq appeal[:issues]
      expect(response_body["docket_number"]).to eq appeal[:docket_number]
      expect(response_body["regional_office"]).to eq appeal[:regional_office]
      expect(response_body["aod"]).to eq appeal[:aod]
      expect(response_body["cavc"]).to eq appeal[:cavc]
      expect(response_body["type"]).to eq appeal[:type]
    end

    it "should return not found" do
      get :find_appeals_by_veteran_id, veteran_id: "doesnot_exist"
      expect(response.status).to eq 404
    end
  end
end
