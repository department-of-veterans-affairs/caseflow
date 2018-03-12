RSpec.describe IssuesController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

  let(:appeal) { Appeal.create(vacols_id: "354672") }

  describe "POST appeals/:appeal_id/issues" do
    context "when all parameters are present" do
      let(:params) do
        {
          program: "01",
          issue: "02",
          level_1: "03",
          level_2: "04",
          level_3: "05",
          note: "test"
        }
      end

      it "should be successful" do
        post :create, appeal_id: appeal.id, issues: params
        expect(response.status).to eq 201
        response_body = JSON.parse(response.body)["issue"]
        expect(response_body["codes"]).to eq %w[01 02 03 04 05]
        expect(response_body["labels"]).to eq "not_loaded"
        expect(response_body["vacols_sequence_id"]).to eq 1
        expect(response_body["note"]).to eq "test"
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :create, appeal_id: "3456789", issues: {}
        expect(response.status).to eq 404
      end
    end

    context "when there is an error" do
      let(:params) do
        {
          program: "01",
          issue: "02",
          level_1: "03",
          level_2: "04",
          note: "test"
        }
      end

      let(:result_params) do
        {
          css_id: "DSUSER",
          issue_attrs: params.merge(vacols_id: appeal.vacols_id).stringify_keys
        }
      end

      it "should return bad request" do
        allow(Fakes::IssueRepository).to receive(:create_vacols_issue!)
          .with(result_params).and_raise(IssueRepository::IssueError.new("Invalid codes"))

        post :create, appeal_id: appeal.id, issues: params
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(error["title"]).to eq "IssueRepository::IssueError"
        expect(error["detail"]).to eq "Invalid codes"
      end
    end
  end

  describe "PATCH appeals/:appeal_id/issues/:vacols_sequence_id" do
    context "when all parameters are present" do
      let(:params) do
        {
          program: "01",
          issue: "02",
          level_1: "03",
          level_2: "04",
          note: "test"
        }
      end

      let(:result_params) do
        {
          css_id: "DSUSER",
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: "1",
          issue_attrs: params.stringify_keys
        }
      end

      it "should be successful" do
        allow(Fakes::IssueRepository).to receive(:update_vacols_issue!)
          .with(result_params).and_return({})
        post :update, appeal_id: appeal.id, vacols_sequence_id: 1, issues: params
        expect(response.status).to eq 200
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :update, appeal_id: 45_545_454, vacols_sequence_id: 1, issues: {}
        expect(response.status).to eq 404
      end
    end

    context "when there is an error" do
      let(:params) do
        {
          program: "01",
          issue: "02",
          level_1: "03",
          level_2: "04",
          note: "test"
        }
      end

      let(:result_params) do
        {
          css_id: "DSUSER",
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: "1",
          issue_attrs: params.stringify_keys
        }
      end

      it "should not be successful" do
        allow(Fakes::IssueRepository).to receive(:update_vacols_issue!)
          .with(result_params).and_raise(IssueRepository::IssueError.new("Invalid codes"))

        post :update, appeal_id: appeal.id, vacols_sequence_id: 1, issues: params
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(error["title"]).to eq "IssueRepository::IssueError"
        expect(error["detail"]).to eq "Invalid codes"
      end
    end
  end

  describe "DELETE appeals/:appeal_id/issues/:vacols_sequence_id" do
    context "when deleted successfully" do
      let(:result_params) do
        {
          css_id: "DSUSER",
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: "1",
        }
      end
      it "should be successful" do
        allow(Fakes::IssueRepository).to receive(:delete_vacols_issue!)
          .with(result_params).and_return({})
        post :destroy, appeal_id: appeal.id, vacols_sequence_id: 1
        expect(response.status).to eq 200
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :destroy, appeal_id: 45_545_454, vacols_sequence_id: 1, issues: {}
        expect(response.status).to eq 404
      end
    end

    context "when there is an error" do
      let(:result_params) do
        {
          css_id: "DSUSER",
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: "1",
        }
      end
      it "should not be successful" do
        allow(Fakes::IssueRepository).to receive(:delete_vacols_issue!)
          .with(result_params).and_raise(IssueRepository::IssueError.new("Cannot find issue"))
        post :destroy, appeal_id: appeal.id, vacols_sequence_id: 1
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(error["title"]).to eq "IssueRepository::IssueError"
        expect(error["detail"]).to eq "Cannot find issue"
      end
    end
  end
end
