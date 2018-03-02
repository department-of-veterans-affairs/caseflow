RSpec.describe IssuesController, type: :controller do
  before do
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

  let(:appeal) { Appeal.create(vacols_id: "354672") }

  describe "POST appeals/:appeal_id/issues" do
    context "when all parameters are present" do
      before do
        allow(IssueRepository).to receive(:create_vacols_issue)
          .with("DSUSER", params.merge(vacols_id: appeal.vacols_id))
          .and_return(OpenStruct.new)
      end

      let(:params) do
        {
          program: "02",
          issue: "14",
          level_1: "01",
          level_2: "88",
          note: "test"
        }
      end

      it "should be successful" do
        User.authenticate!(roles: ["System Admin"])
        post :create, appeal_id: appeal.id, issues: params
        expect(response.status).to eq 201
      end
    end

    context "when appeal is not found" do
      before do
        allow(IssueRepository).to receive(:create_vacols_issue).and_return(OpenStruct.new)
      end

      let(:params) do
        {
          program: "02",
          issue: "14",
          level_1: "01",
          level_2: "88",
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
          program: "02",
          issue: "14",
          level_1: "01",
          level_2: "88",
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
