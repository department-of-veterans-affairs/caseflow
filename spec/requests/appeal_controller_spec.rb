RSpec.describe "Reader Appeal Requests", type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:vacols_record) { :remand_decided }
  let(:appeal) { Generators::Appeal.build(vbms_id: "123456789S", vacols_record: vacols_record) }
  let(:appeal_with_no_issues) { Generators::Appeal.build(vbms_id: "123456788S", vacols_record: vacols_record, issues: [] )}
  
  describe "Appeals Find by Veteran ID Endpoint" do
    let(:headers) { { "HTTP_VETERAN_ID": "111225555S" } }

    it "returns not found" do
      headers["HTTP_VETERAN_ID"] = "22221C"
      get "/reader/appeal/veteran-id", nil, headers
      expect(response).to have_http_status(:not_found)

      headers["HTTP_VETERAN_ID"] = "22112121xs"
      get "/reader/appeal/veteran-id", nil, headers
      expect(response).to have_http_status(:not_found)
    end

    it "passes the request " do
      headers["HTTP_VETERAN_ID"] = appeal[:vbms_id]
      get "/reader/appeal/veteran-id", nil, headers
      expect(response).to have_http_status(:success)
    end

    it "doesn't return appeals without issues" do
      headers["HTTP_VETERAN_ID"] = appeal_with_no_issues[:vbms_id]
      get "/reader/appeal/veteran-id", nil, headers
      expect(JSON.parse(response.body)["appeals"].size).to be(0)
    end

    it "fails routing validation" do
      headers["HTTP_VETERAN_ID"] = "2"
      get "/reader/appeal/veteran-id", nil, headers
      expect(response).to have_http_status(:not_acceptable)

      headers["HTTP_VETERAN_ID"] = nil
      get "/reader/appeal/veteran-id", nil, headers
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
