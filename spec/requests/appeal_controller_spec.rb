RSpec.describe "Reader Appeal Requests", type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:vacols_record) { :remand_decided }
  let(:appeal) do
    create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "123456789S", case_issues: [create(:case_issue)]))
  end
  let(:appeal_with_no_issues) do
    create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "123456788S", case_issues: []))
  end

  describe "Appeals Find by Veteran ID Endpoint" do
    let(:headers) { { "HTTP_VETERAN_ID": "111225555S" } }

    it "passes the request " do
      headers["HTTP_VETERAN_ID"] = appeal[:vbms_id]
      get "/reader/appeal/veteran-id", params: nil, headers: headers
      expect(response).to have_http_status(:success)
    end

    it "doesn't return appeals without issues" do
      headers["HTTP_VETERAN_ID"] = appeal_with_no_issues[:vbms_id]
      get "/reader/appeal/veteran-id", params: nil, headers: headers
      expect(JSON.parse(response.body)["appeals"].size).to be(0)
    end
  end

  describe "Appeals controller #show in html" do
    it "redirects the page to Case page" do
      get "/reader/appeal/#{appeal.vacols_id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
