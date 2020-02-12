# frozen_string_literal: true

RSpec.describe "Reader Appeal Requests", :all_dbs, type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }
  let(:appeal) do
    create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "123456789S", case_issues: [create(:case_issue)]))
  end

  describe "Appeals controller #show in html" do
    it "redirects the page to Case page" do
      get "/reader/appeal/#{appeal.vacols_id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
