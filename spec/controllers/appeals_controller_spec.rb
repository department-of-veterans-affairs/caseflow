RSpec.describe AppealsController, type: :controller do
  before do
    Fakes::Initializer.load!

    FeatureToggle.enable!(:queue_welcome_gate)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
  end

  describe "GET appeals" do
    let(:ssn) { 100_000_000 + SecureRandom.random_number(899_999_999) }
    let(:appeal) { Generators::Appeal.create(vbms_id: "#{ssn}S") }
    let(:veteran_id) { appeal.vbms_id }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :list
        expect(response.status).to eq 400
      end
    end

    context "when request header contains Veteran ID" do
      it "array in response contains one appeal" do
        request.headers["HTTP_VETERAN_ID"] = veteran_id
        get :list
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["appeals"].size).to eq 1
      end
    end
  end
end
