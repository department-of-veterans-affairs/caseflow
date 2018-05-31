RSpec.describe BeaamAppealsController, type: :controller do
  before do
    User.authenticate!(roles: ["System Admin"])
    FeatureToggle.enable!(:queue_beaam_appeals)
  end

  after do
    FeatureToggle.disable!(:queue_beaam_appeals)
  end

  describe "GET beaam_appeals" do
    let(:bgs_veteran_record) do
      {
        first_name: "Bob",
        middle_name: "Rob",
        last_name: "Smith",
        sex: "M",
        date_of_birth: "05/04/1955"
      }
    end
    let!(:appeals) do
      [
        FactoryBot.create(:appeal, veteran: FactoryBot.create(:veteran, bgs_veteran_record: bgs_veteran_record)),
        FactoryBot.create(:appeal, veteran: FactoryBot.create(:veteran))
      ]
    end

    context "when request header does not contain Veteran ID" do
      it "response should error" do
        get :index
        expect(response.status).to eq 200

        returned_appeals = JSON.parse(response.body)["appeals"]["data"]
        expect(returned_appeals.count).to eq(2)

        attributes = returned_appeals[0]["attributes"]

        expect(attributes["veteran_full_name"]).to eq("Bob Smith")
        expect(attributes["veteran_gender"]).to eq(bgs_veteran_record[:sex])
        expect(attributes["veteran_date_of_birth"]).to eq(bgs_veteran_record[:date_of_birth])
      end
    end
  end
end
