RSpec.describe QueueController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_welcome_gate)
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
  end

  describe "GET queue/judges" do
    it "should be successful" do
      User.authenticate!(roles: ["System Admin"])
      get :judges
      expect(response.status).to eq 200
      response_body = JSON.parse(response.body)
      expect(response_body["judges"].size).to eq 3
    end
  end

  describe "POST queue/tasks/:task_id/complete" do
    let(:judge) { User.create(css_id: "CFS123", station_id: Judge::JUDGE_STATION_ID) }

    context "when all parameters are present" do
      let(:params) do
        {
          "type": "OMORequest",
          "reviewing_judge_id": judge.id,
          "work_product": "OMO - IME",
          "document_id": "123456789.1234",
          "overtime": true,
          "note": "something"
        }
      end

      it "should be successful" do
        User.authenticate!(roles: ["System Admin"])
        post :complete, task_id: "1234567-2016-11-05", queue: params
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["document_id"]).to eq "123456789.1234"
        expect(response_body["overtime"]).to eq true
        expect(response_body["note"]).to eq "something"
      end
    end

    context "when not all parameters are present" do
      let(:params) do
        {
          "type": "OMORequest",
          "work_product": "OMO - IME",
          "document_id": "123456789.1234",
          "overtime": true,
          "note": "something"
        }
      end

      it "should not be successful" do
        User.authenticate!(roles: ["System Admin"])
        post :complete, task_id: "1234567-2016-11-05", queue: params
        expect(response.status).to eq 400
        response_body = JSON.parse(response.body)
        expect(response_body["errors"].first["title"]).to eq "Error Completing Attorney Case Review"
      end
    end
  end
end
