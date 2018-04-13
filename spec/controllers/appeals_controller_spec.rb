RSpec.describe AppealsController, type: :controller do
  before { User.authenticate!(roles: ["System Admin"]) }

  describe "GET appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { Generators::Appeal.create(vbms_id: "#{ssn}S") }
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
end
