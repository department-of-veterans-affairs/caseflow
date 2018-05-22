RSpec.describe AmaAppealsController, type: :controller do

  describe "GET ama_appeals", focus: true do
    let(:bgs_veteran_record) do
      {
        first_name: "Bob",
        middle_name: "Rob",
        last_name: "Smith",
        sex: "M",
        date_of_birth: "05/04/1955"
      }
    end
    let!(:appeal) { create(:appeal, veteran_object: create(:veteran, bgs_veteran_record: bgs_veteran_record)) }

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index
        binding.pry
        expect(response.status).to eq 400
      end
    end
  end
end
