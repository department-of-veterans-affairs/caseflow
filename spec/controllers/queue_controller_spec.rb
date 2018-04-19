RSpec.describe QueueController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_welcome_gate)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
  end

  describe "GET queue/:user_id" do
    let(:user) { User.create(css_id: "TEST1", station_id: 101) }

    it "when user is an attorney, it should process the request succesfully" do
      allow(UserRepository).to receive(:vacols_role).and_return("Attorney")
      get :tasks, params: { user_id: user.id }
      expect(response.status).to eq 200
    end

    it "when user is an judge, it should process the request succesfully" do
      allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Judge")
      get :tasks, params: { user_id: user.id }
      expect(response.status).to eq 200
    end

    it "when user is neither, it should not process the request succesfully" do
      allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Cat")
      get :tasks, params: { user_id: user.id }
      expect(response.status).to eq 400
    end
  end

  describe "POST queue/tasks" do
    let(:attorney) { User.create(css_id: "CFS123", station_id: "101") }
    let(:appeal) { Appeal.create(vacols_id: "1234C") }
    let!(:current_user) { User.authenticate!(roles: ["System Admin"]) }

    before do
      FeatureToggle.enable!(:queue_phase_three)
    end

    after do
      FeatureToggle.disable!(:queue_phase_three)
    end

    context "when current user is an attorney" do
      let(:params) do
        {
          "appeal_id": appeal.id,
          "attorney_id": attorney.id,
          "appeal_type": "Legacy"
        }
      end

      it "should not be successful" do
        post :create, params: { queue: params }
        expect(response.status).to eq 400
        response_body = JSON.parse(response.body)
        expect(response_body["errors"].first["title"]).to eq "Role is Invalid"
      end
    end

    context "when current user is a judge" do
      let(:params) do
        {
          "appeal_id": appeal.id,
          "attorney_id": attorney.id,
          "appeal_type": "Legacy"
        }
      end

      it "should be successful" do
        allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Judge")
        allow(QueueRepository).to receive(:assign_case_to_attorney!).with(
          judge: current_user,
          attorney: attorney,
          vacols_id: appeal.vacols_id
        ).and_return(true)

        post :create, params: { queue: params }
        expect(response.status).to eq 201
      end

      context "when appeal type is invalid" do
        let(:params) do
          {
            "appeal_id": appeal.id,
            "attorney_id": attorney.id,
            "appeal_type": "Unknown"
          }
        end

        it "should not be successful" do
          post :create, params: { queue: params }
          expect(response.status).to eq 400
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["title"]).to eq "Appeal Type is Invalid"
        end
      end

      context "when appeal is not found" do
        let(:params) do
          {
            "appeal_id": 4_646_464,
            "attorney_id": attorney.id,
            "appeal_type": "Legacy"
          }
        end

        it "should not be successful" do
          allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Judge")
          post :create, params: { queue: params }
          expect(response.status).to eq 404
        end
      end

      context "when attorney is not found" do
        let(:params) do
          {
            "appeal_id": appeal.id,
            "attorney_id": 7_777_777_777,
            "appeal_type": "Legacy"
          }
        end

        it "should not be successful" do
          allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Judge")
          post :create, params: { queue: params }
          expect(response.status).to eq 404
        end
      end
    end
  end

  describe "POST queue/tasks/:task_id/complete" do
    let(:judge) { User.create(css_id: "CFS123", station_id: User::BOARD_STATION_ID) }

    before do
      FeatureToggle.enable!(:queue_phase_two)
    end

    after do
      FeatureToggle.disable!(:queue_phase_two)
    end

    context "when all parameters are present to create OMORequest" do
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
        post :complete, params: { task_id: "1234567-2016-11-05", queue: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorney_case_review"]["document_id"]).to eq "123456789.1234"
        expect(response_body["attorney_case_review"]["overtime"]).to eq true
        expect(response_body["attorney_case_review"]["note"]).to eq "something"
        expect(response_body.keys).to_not include "issues"
      end
    end

    context "when all parameters are present to create DraftDecision" do
      let(:params) do
        {
          "type": "DraftDecision",
          "reviewing_judge_id": judge.id,
          "work_product": "Decision",
          "document_id": "123456789.1234",
          "overtime": true,
          "note": "something",
          "issues": [{ "disposition": "Remanded", "vacols_sequence_id": 1 },
                     { "disposition": "Allowed", "vacols_sequence_id": 2 }]
        }
      end

      it "should be successful" do
        allow(Fakes::IssueRepository).to receive(:update_vacols_issue!)
        User.authenticate!(roles: ["System Admin"])
        post :complete, params: { task_id: "1234567-2016-11-05", queue: params }
        expect(response.status).to eq 200
        response_body = JSON.parse(response.body)
        expect(response_body["attorney_case_review"]["document_id"]).to eq "123456789.1234"
        expect(response_body["attorney_case_review"]["overtime"]).to eq true
        expect(response_body["attorney_case_review"]["note"]).to eq "something"
        expect(response_body.keys).to include "issues"
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
        post :complete, params: { task_id: "1234567-2016-11-05", queue: params }
        expect(response.status).to eq 400
        response_body = JSON.parse(response.body)
        expect(response_body["errors"].first["title"]).to eq "ActiveRecord::RecordInvalid"
        expect(response_body["errors"].first["detail"]).to eq "Validation failed: Reviewing judge can't be blank"
      end
    end
  end
end
