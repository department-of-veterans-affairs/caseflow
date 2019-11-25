# frozen_string_literal: true

RSpec.describe "Session", :postgres, type: :request do
  let(:appeal) { Generators::LegacyAppeal.build(vacols_record: :ready_to_certify) }

  before do
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "405", "email" => "test@example.com"
    }
  end

  context "when regional office is not set" do
    it "user should not be authenticated" do
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to eq 302
    end
  end

  context "error handling" do
    it "returns a 400 when the regional_office param is not set" do
      patch "/sessions/update"
      expect(status).to eq 400
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Required parameter 'regional_office' is missing.")
    end
  end

  context "when regional office is set" do
    it "user should be authenticated" do
      patch "/sessions/update", params: { regional_office: "RO05" }
      expect(status).to eq 200
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to_not eq 302
    end

    it "user should be able to log out" do
      patch "/sessions/update", params: { regional_office: "RO05" }
      expect(status).to eq 200
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to_not eq 302
      get "/logout"
      expect(status).to eq 302
      get "/certifications/new/#{appeal.vacols_id}"
      expect(status).to eq 302
    end
  end
end
