RSpec.describe "Reader Appeal Requests", type: :request, focus: true do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }

  describe "Appeals controller #show in html" do
    it "redirects the page to Case page" do
      get "/reader/appeal/#{appeal.vacols_id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
