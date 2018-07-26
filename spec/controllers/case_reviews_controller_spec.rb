RSpec.describe CaseReviewsController, type: :controller do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:test_facols)
    User.authenticate!(roles: ["System Admin"])
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  describe "POST case_reviews/:task_id/complete" do
    let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
    let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID) }

    let(:judge_staff) { create(:staff, :judge_role, slogid: "CSF444", sdomainid: judge.css_id) }
    let(:attorney_staff) { create(:staff, :attorney_role, slogid: "CSF555", sdomainid: attorney.css_id) }

    let(:task_id) { "#{vacols_case.bfkey}-#{vacols_case.decass.first.deadtim.strftime('%Y-%m-%d')}" }
    let(:vacols_issue_remanded) { create(:case_issue, :disposition_remanded, isskey: vacols_case.bfkey) }
    let(:vacols_issue_allowed) { create(:case_issue, :disposition_allowed, isskey: vacols_case.bfkey) }

    context "Attorney Case Review" do
      before do
        User.stub = attorney
      end

      let(:vacols_case) { create(:case, :assigned, bfcurloc: attorney_staff.slogid) }

      context "when all parameters are present to create OMO request" do
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
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
        end
      end

      context "when all parameters are present to create Draft Decision" do
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"],
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
            "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
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

    context "Judge Case Review" do
      before do
        User.stub = judge
        expect(QueueRepository).to receive(:sign_decision_or_create_omo!).and_return(true)
      end

      let(:vacols_case) { create(:case, :assigned, bfcurloc: judge_staff.slogid) }

      context "when all parameters are present to send to omo office" do
        let(:params) do
          {
            "type": "JudgeCaseReview",
            "location": "omo_office",
            "attorney_id": attorney.id
          }
        end

        it "should be successful" do
          post :complete, params: { task_id: task_id, tasks: params }
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["location"]).to eq "omo_office"
        end
      end

      context "when all parameters are present to send to sign a decision" do
        let(:params) do
          {
            "type": "JudgeCaseReview",
            "location": "bva_dispatch",
            "attorney_id": attorney.id,
            "complexity": "easy",
            "quality": "meets_expectations",
            "comment": "do this",
            "factors_not_considered": %w[theory_contention relevant_records],
            "areas_for_improvement": ["process_violations"],
            "issues": [{ "disposition": "1", "vacols_sequence_id": vacols_issue_remanded.issseq },
                       { "disposition": "3", "vacols_sequence_id": vacols_issue_allowed.issseq }]
          }
        end

        it "should be successful" do
          post :complete, params: { task_id: task_id, tasks: params }
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)
          expect(response_body["task"]["location"]).to eq "bva_dispatch"
          expect(response_body["task"]["judge_id"]).to eq judge.id
          expect(response_body["task"]["attorney_id"]).to eq attorney.id
          expect(response_body["task"]["complexity"]).to eq "easy"
          expect(response_body["task"]["quality"]).to eq "meets_expectations"
          expect(response_body["task"]["comment"]).to eq "do this"
          expect(response_body.keys).to include "issues"
          expect(response_body["issues"].select do |i|
            i["vacols_sequence_id"] == vacols_issue_remanded.issseq
          end.first["disposition"]).to eq "allowed"
          expect(response_body["issues"].select do |i|
            i["vacols_sequence_id"] == vacols_issue_allowed.issseq
          end.first["disposition"]).to eq "remanded"
        end
      end
    end
  end
end
