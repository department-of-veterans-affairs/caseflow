RSpec.describe AmaAppealsController, type: :controller do

  describe "GET ama_appeals" do
    let(:ssn) { Generators::Random.unique_ssn }
    let(:appeal) { Generators::LegacyAppeal.create(vbms_id: "#{ssn}S") }
    let(:veteran_id) { appeal.vbms_id }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index
        expect(response.status).to eq 400
      end
    end
  end
end
