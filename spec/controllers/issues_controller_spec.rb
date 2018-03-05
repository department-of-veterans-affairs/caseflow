RSpec.describe IssuesController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

  let(:appeal) { Appeal.create(vacols_id: "354672") }

  describe "POST appeals/:appeal_id/issues" do
    context "when all parameters are present" do
      let(:params) do
        {
          program: { description: "test1", code: "01" },
          issue: { description: "test2", code: "02" },
          level_1: { description: "test3", code: "03" },
          level_2: { description: "test4", code: "04" },
          note: "test"
        }
      end

      it "should be successful" do
        User.authenticate!(roles: ["System Admin"])
        post :create, appeal_id: appeal.id, issues: params
        expect(response.status).to eq 201
        response_body = JSON.parse(response.body)["issue"]
        expect(response_body["codes"]).to eq %w[01 02 03 04]
        expect(response_body["labels"]).to eq %w[test1 test2 test3 test4]
        expect(response_body["vacols_sequence_id"]).to eq 1
        expect(response_body["note"]).to eq "test"
      end
    end

    context "when appeal is not found" do
      let(:params) do
        {
          program: { description: "test1", code: "01" },
          issue: { description: "test2", code: "02" },
          level_1: { description: "test3", code: "03" },
          level_2: { description: "test4", code: "04" },
          note: "test"
        }
      end

      it "should return not found" do
        User.authenticate!(roles: ["System Admin"])
        post :create, appeal_id: "3456789", issues: params
        expect(response.status).to eq 404
      end
    end

    context "when there is an error" do
      let(:params) do
        {
          program: { description: "test1", code: "01" },
          issue: { description: "test2", code: "02" },
          level_1: { description: "test3", code: "03" },
          level_2: { description: "test4", code: "04" },
          note: "test"
        }
      end

      it "should return bad request" do
        allow(Issue).to receive(:create!).and_return(nil)
        User.authenticate!(roles: ["System Admin"])
        post :create, appeal_id: appeal.id, issues: params
        expect(response.status).to eq 400
      end
    end
  end
end
