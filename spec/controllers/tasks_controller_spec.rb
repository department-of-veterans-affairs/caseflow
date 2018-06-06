RSpec.describe TasksController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:judge_queue)
    FeatureToggle.enable!(:test_facols)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:judge_queue)
  end

  describe "GET tasks?user_id=xxx" do
    let(:user) { FactoryBot.create(:user) }
    before do
      User.stub = user
      FactoryBot.create(:staff, role, sdomainid: user.css_id)
    end

    context "user is an attorney" do
      let(:role) { :attorney_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 200
      end
    end

    context "user is a judge" do
      let(:role) { :judge_role }

      it "should process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 200
      end
    end

    context "user is neither judge nor attorney" do
      let(:role) { nil }

      it "should not process the request succesfully" do
        get :index, params: { user_id: user.id }
        expect(response.status).to eq 302
      end
    end
  end

  describe "POST /tasks" do
    let(:attorney) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }
    let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
    before do
      User.stub = user
      FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)
    end

    context "Co-located admin action" do
      before do
        FeatureToggle.enable!(:attorney_assignment)
      end

      after do
        FeatureToggle.disable!(:attorney_assignment)
      end

      context "when current user is a judge" do
        let(:role) { :judge_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "type": "CoLocatedAdminAction"
          }
        end

        it "should not be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 302
        end
      end

      context "when current user is an attorney" do
        let(:role) { :attorney_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "type": "CoLocatedAdminAction",
            "title": "address_verification",
            "instructions": "do this"
          }
        end

        it "should be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 201
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["status"]).to eq "assigned"
          expect(response_body["task"]["appeal_id"]).to eq appeal.id
          expect(response_body["task"]["instructions"]).to eq "do this"
          expect(response_body["task"]["title"]).to eq "address_verification"
        end

        context "when appeal is not found" do
          let(:params) do
            {
              "appeal_id": 4_646_464,
              "type": "CoLocatedAdminAction",
              "title": "address_verification"
            }
          end

          it "should not be successful" do
            post :create, params: { tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["detail"]).to eq "Appeal can't be blank"
          end
        end
      end
    end

    context "Judge case assignment" do
      before do
        FeatureToggle.enable!(:judge_assignment)
      end

      after do
        FeatureToggle.disable!(:judge_assignment)
      end

      context "when current user is an attorney" do
        let(:role) { :attorney_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "assigned_to_id": user.id,
            "type": "JudgeCaseAssignmentToAttorney"
          }
        end

        it "should not be successful" do
          post :create, params: { tasks: params }
          expect(response.status).to eq 302
        end
      end

      context "when current user is a judge" do
        let(:role) { :judge_role }
        let(:params) do
          {
            "appeal_id": appeal.id,
            "assigned_to_id": attorney.id,
            "type": "JudgeCaseAssignmentToAttorney"
          }
        end

        it "should be successful" do
          allow(QueueRepository).to receive(:assign_case_to_attorney!).with(
            judge: user,
            attorney: attorney,
            vacols_id: appeal.vacols_id
          ).and_return(true)

          post :create, params: { tasks: params }
          expect(response.status).to eq 201
        end

        context "when appeal is not found" do
          let(:params) do
            {
              "appeal_id": 4_646_464,
              "assigned_to_id": attorney.id,
              "type": "JudgeCaseAssignmentToAttorney"
            }
          end

          it "should not be successful" do
            post :create, params: { tasks: params }
            expect(response.status).to eq 404
          end
        end

        context "when attorney is not found" do
          let(:params) do
            {
              "appeal_id": appeal.id,
              "assigned_to_id": 7_777_777_777,
              "type": "JudgeCaseAssignmentToAttorney"
            }
          end

          it "should not be successful" do
            allow(Fakes::UserRepository).to receive(:vacols_role).and_return("Judge")
            post :create, params: { tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["detail"]).to eq "Assigned to can't be blank"
          end
        end
      end
    end
  end

  describe "PATCH tasks/:id" do
    let(:attorney) { FactoryBot.create(:user) }
    let(:user) { FactoryBot.create(:user) }
    before do
      User.stub = user
      FactoryBot.create(:staff, role, sdomainid: user.css_id)
      FactoryBot.create(:staff, :attorney_role, sdomainid: attorney.css_id)

      FeatureToggle.enable!(:judge_assignment)
    end

    after do
      FeatureToggle.disable!(:judge_assignment)
    end

    context "when current user is an attorney" do
      let(:role) { :attorney_role }
      let(:params) do
        {
          "assigned_to_id": user.id,
          "type": "JudgeCaseAssignmentToAttorney"
        }
      end

      it "should not be successful" do
        patch :update, params: { tasks: params, id: "3615398-2018-04-18" }
        expect(response.status).to eq 302
      end
    end

    context "when current user is a judge" do
      let(:role) { :judge_role }
      let(:params) do
        {
          "assigned_to_id": attorney.id,
          "type": "JudgeCaseAssignmentToAttorney"
        }
      end

      it "should be successful" do
        allow(QueueRepository).to receive(:reassign_case_to_attorney!).with(
          judge: user,
          attorney: attorney,
          vacols_id: "3615398",
          created_in_vacols_date: "2018-04-18".to_date
        ).and_return(true)

        patch :update, params: { tasks: params, id: "3615398-2018-04-18" }
        expect(response.status).to eq 200
      end

      context "when attorney is not found" do
        let(:params) do
          {
            "assigned_to_id": 7_777_777_777,
            "type": "JudgeCaseAssignmentToAttorney"
          }
        end

        it "should not be successful" do
          patch :update, params: { tasks: params, id: "3615398-2018-04-18" }
          expect(response.status).to eq 400
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["detail"]).to eq "Assigned to can't be blank"
        end
      end
    end
  end

  describe "POST tasks/:task_id/complete" do
    let(:judge) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID) }
    let(:vacols_staff) { FactoryBot.create(:staff, :judge_role, :has_location_code, sdomainid: judge.css_id) }
    let(:vacols_case) { FactoryBot.create(:case, :assigned, bfcurloc: vacols_staff.slogid) }
    let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass.first.deadtim.strftime('%Y-%m-%d')}" }

    before do
      User.stub = judge
      FeatureToggle.enable!(:queue_phase_two)
    end

    after do
      FeatureToggle.disable!(:queue_phase_two)
    end

    context "Attorney Case Review" do
      context "when all parameters are present to create OMO request" do
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": "omo_request",
            "reviewing_judge_id": judge.id,
            "work_product": "OMO - IME",
            "document_id": "123456789.1234",
            "overtime": true,
            "note": "something"
          }
        end

        it "should be successful" do
          post :complete, params: { task_id: task_id, tasks: params }
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["document_id"]).to eq "123456789.1234"
          expect(response_body["task"]["overtime"]).to eq true
          expect(response_body["task"]["note"]).to eq "something"
          expect(response_body.keys).to_not include "issues"
        end
      end

      context "when all parameters are present to create Draft Decision" do
        let(:vacols_issue_remanded) { FactoryBot.create(:case_issue, :disposition_remanded, isskey: vacols_case.bfkey) }
        let(:vacols_issue_allowed) { FactoryBot.create(:case_issue, :disposition_allowed, isskey: vacols_case.bfkey) }
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": "draft_decision",
            "reviewing_judge_id": judge.id,
            "work_product": "Decision",
            "document_id": "123456789.1234",
            "overtime": true,
            "note": "something",
            "issues": [{ "disposition": "3", "vacols_sequence_id": vacols_issue_remanded.issseq },
                       { "disposition": "1", "vacols_sequence_id": vacols_issue_allowed.issseq }]
          }
        end

        it "should be successful" do
          post :complete, params: { task_id: task_id, tasks: params }
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["document_id"]).to eq "123456789.1234"
          expect(response_body["task"]["overtime"]).to eq true
          expect(response_body["task"]["note"]).to eq "something"
          expect(response_body.keys).to include "issues"
        end
      end

      context "when not all parameters are present" do
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": "omo_request",
            "work_product": "OMO - IME",
            "document_id": "123456789.1234",
            "overtime": true,
            "note": "something"
          }
        end

        it "should not be successful" do
          post :complete, params: { task_id: task_id, tasks: params }
          expect(response.status).to eq 400
          response_body = JSON.parse(response.body)
          expect(response_body["errors"].first["title"]).to eq "Record is invalid"
          expect(response_body["errors"].first["detail"]).to eq "Reviewing judge can't be blank"
        end
      end
    end
  end
end
