RSpec.describe HearingsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearings"]) }
  let(:hearing) { Generators::Hearing.create }

  describe "PATCH update" do
    it "should be succesful" do
      patch :update, id: hearing.id, hearing: { notes: "Test", hold_open: 30, transcript_requested: false }
      expect(response.status).to eq 200
    end

    it "should return not found" do
      patch :update, id: "78484", hearing: { notes: "Test", hold_open: 30, transcript_requested: false }
      expect(response.status).to eq 404
    end
  end
end
