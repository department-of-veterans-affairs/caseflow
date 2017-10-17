RSpec.describe HearingsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let(:hearing) { Generators::Hearing.create }

  describe "PATCH update" do
    it "should be successful" do
      params = { notes: "Test",
                 hold_open: 30,
                 transcript_requested: false,
                 aod: :granted,
                 add_on: true,
                 disposition: :held }
      patch :update, id: hearing.id, hearing: params
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["notes"]).to eq "Test"
      expect(response_body["hold_open"]).to eq "30"
      expect(response_body["transcript_requested"]).to eq false
      expect(response_body["aod"]).to eq "granted"
      expect(response_body["disposition"]).to eq "held"
      expect(response_body["add_on"]).to eq true
    end

    it "should return not found" do
      patch :update, id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false }
      expect(response.status).to eq 404
    end
  end
end
