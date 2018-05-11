RSpec.describe AppealsController, type: :controller do
  before { User.authenticate!(roles: ["System Admin"]) }

  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { Generators::LegacyAppeal.create(vbms_id: "#{ssn}S") }
    let(:veteran_id) { appeal.vbms_id }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index
        expect(response.status).to eq 400
      end
    end

    context "when request header contains Veteran ID with associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = veteran_id }

      it "returns valid response with one appeal" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 1
      end
    end

    context "when request header contains Veteran ID with no associated appeals" do
      before { request.headers["HTTP_VETERAN_ID"] = "#{Generators::Random.unique_ssn}S" }

      it "returns valid response with empty appeals array" do
        get :index
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 0
      end
    end
  end

  describe "GET appeals/appeal_id/document_count" do
    context "when appeal has documents" do
      let(:documents) do
        [
          Document.new(type: "SSOC", received_at: 6.days.ago),
          Document.new(type: "SSOC", received_at: 7.days.ago)
        ]
      end
      let(:appeal) { Generators::LegacyAppeal.create(vacols_id: "654321", documents: documents) }

      it "should return document count" do
        get :document_count, params: { appeal_id: appeal.vacols_id }
        response_body = JSON.parse(response.body)
        expect(response_body["document_count"]).to eq 2
      end
    end

    context "when appeal is not found" do
      it "should return status 404" do
        get :document_count, params: { appeal_id: "123456" }
        expect(response.status).to eq 404
      end
    end
  end
end
