# frozen_string_literal: true

RSpec.describe CaseReviewsController, :all_dbs, type: :controller do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["System Admin"])
  end

  context "Ama appeal" do
    describe "POST case_reviews/:task_id/complete" do
      let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
      let(:attorney) { create(:user, station_id: User::BOARD_STATION_ID) }

      let!(:judge_staff) { create(:staff, :judge_role, slogid: "CSF444", sdomainid: judge.css_id) }
      let!(:attorney_staff) { create(:staff, :attorney_role, slogid: "CSF555", sdomainid: attorney.css_id) }

      let!(:request_issue1) { create(:request_issue, decision_review: task.appeal) }
      let(:request_issue2) { create(:request_issue, decision_review: task.appeal) }
      let(:request_issue3) { create(:request_issue, decision_review: task.appeal) }

      context "Attorney Case Review" do
        shared_examples "valid params" do
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task.id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "12345678.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(response_body.keys).to include "issues"

            expect(DecisionIssue.count).to eq 2
            expect(request_issue1.decision_issues.first.disposition).to eq "allowed"
            expect(request_issue1.decision_issues.first.description).to eq "wonderful life"
            expect(request_issue1.decision_issues.first.benefit_type).to eq "pension"
            expect(request_issue3.decision_issues.first.disposition).to eq "allowed"
            expect(request_issue3.decision_issues.first.description).to eq "wonderful life"
            expect(request_issue3.decision_issues.first.benefit_type).to eq "pension"
            expect(request_issue3.decision_issues.first.diagnostic_code).to eq diagnostic_code

            expect(request_issue2.decision_issues.first.disposition).to eq "remanded"
            expect(request_issue2.decision_issues.first.description).to eq "great moments"
            expect(request_issue2.decision_issues.first.benefit_type).to eq "vha"
            expect(request_issue2.decision_issues.first.diagnostic_code).to eq "5002"
            expect(request_issue2.decision_issues.first.remand_reasons.size).to eq 1
            expect(request_issue2.decision_issues.first.remand_reasons.first.code).to eq "va_records"
            expect(request_issue2.decision_issues.first.remand_reasons.first.post_aoj).to eq true

            expect(task.reload.status).to eq "completed"
            expect(task.closed_at).to_not eq nil
            expect(task.parent.reload.status).to eq "assigned"
            expect(task.parent.type).to eq JudgeDecisionReviewTask.name

            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)

            expect(AttorneyCaseReview.find_by(task: task).appeal_id).to eq task.appeal.id
          end
        end

        before do
          User.stub = attorney
        end

        let(:root_task) { create(:root_task) }
        let(:judge_task) { create(:ama_judge_decision_review_task, assigned_to: judge, parent: root_task) }
        let(:task) { create(:ama_attorney_task, assigned_to: attorney, assigned_by: judge, parent: judge_task) }

        let(:disposition) { "allowed" }
        let(:request_issue_ids) { [request_issue1.id, request_issue3.id] }
        let(:diagnostic_code) { "5001" }
        let(:params) do
          {
            "type": "AttorneyCaseReview",
            "document_type": Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"],
            "reviewing_judge_id": judge.id,
            "work_product": "Decision",
            "document_id": "12345678.1234",
            "overtime": true,
            "note": "something",
            "issues": [{ "disposition": disposition,
                         "description": "wonderful life",
                         "benefit_type": "pension",
                         "diagnostic_code": diagnostic_code,
                         "request_issue_ids": request_issue_ids },
                       { "disposition": "remanded",
                         "description": "great moments",
                         "benefit_type": "vha",
                         "diagnostic_code": "5002",
                         "request_issue_ids": [request_issue2.id],
                         "remand_reasons": [{ "code": "va_records", "post_aoj": true }] }]
          }
        end

        subject { post :complete, params: { task_id: task.id, tasks: params }, as: :json }

        context "when creating a draft decision" do
          context "when missing dispositions" do
            let(:disposition) { nil }

            it "should not be successful" do
              subject
              expect(response.status).to eq 400
              response_body = JSON.parse(response.body)
              msg = "Validation failed: Disposition can't be blank, Disposition is not included in the list"
              expect(response_body["errors"].first["detail"]).to eq msg
            end
          end

          context "when not all request issues are sent" do
            let(:request_issue_ids) { [request_issue3.id] }

            it "should not be successful" do
              subject
              expect(response.status).to eq 400
              response_body = JSON.parse(response.body)
              expect(response_body["errors"].first["detail"]).to eq "Not every request issue has a decision issue"
            end
          end

          context "when missing diagnostic code" do
            let(:diagnostic_code) { nil }
            it_behaves_like "valid params"
          end

          context "when all parameters are present" do
            it_behaves_like "valid params"
          end
        end
      end

      context "Judge Case Review" do
        before do
          User.stub = judge
        end

        let(:root_task) { create(:root_task) }
        let(:task) { create(:ama_judge_assign_task, assigned_to: judge, parent: root_task) }

        before do
          # Add somebody to the BVA dispatch team so automatic task assignment for AMA cases succeeds.
          BvaDispatch.singleton.add_user(create(:user))
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
              "issues": [{ "disposition": "denied",
                           "request_issue_ids": [request_issue1.id],
                           "description": "wonderful life",
                           "benefit_type": "pension",
                           "diagnostic_code": "5001" },
                         { "disposition": "remanded",
                           "request_issue_ids": [request_issue2.id],
                           "description": "wonderful life",
                           "benefit_type": "pension",
                           "diagnostic_code": "5001",
                           "remand_reasons": [{ "code": "va_records", "post_aoj": true }] }]
            }
          end

          it "should be successful" do
            post :complete, params: { task_id: task.id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            location = response_body["task"]["location"]
            # We send a sampling of cases to quality review, either location is correct
            expect(location == "bva_dispatch" || location == "quality_review").to eq true
            expect(response_body["task"]["judge_id"]).to eq judge.id
            expect(response_body["task"]["attorney_id"]).to eq attorney.id
            expect(response_body["task"]["complexity"]).to eq "easy"
            expect(response_body["task"]["quality"]).to eq "meets_expectations"
            expect(response_body["task"]["comment"]).to eq "do this"
            expect(response_body["task"]["factors_not_considered"]).to eq %w[theory_contention relevant_records]
            expect(response_body["task"]["areas_for_improvement"]).to eq ["process_violations"]
            expect(request_issue1.decision_issues.first.disposition).to eq "denied"
            expect(request_issue2.decision_issues.first.disposition).to eq "remanded"
            expect(task.reload.status).to eq "completed"
            expect(task.closed_at).to_not eq nil

            # When a judge completes judge checkout we create either a QR or dispatch task.
            quality_review_task = QualityReviewTask.find_by(parent_id: root_task.id)
            expect(quality_review_task.assigned_to).to eq(QualityReview.singleton) if quality_review_task
            dispatch_task = BvaDispatchTask.find_by(parent_id: root_task.id)
            expect(dispatch_task.assigned_to).to eq(BvaDispatch.singleton) if dispatch_task

            expect(JudgeCaseReview.find_by(task: task).appeal_id).to eq task.appeal.id
          end

          context "when case is being QRed" do
            let(:qr_user) { create(:user) }
            let!(:quality_review_organization_task) do
              create(:qr_task, assigned_to: QualityReview.singleton, parent: root_task)
            end
            let!(:quality_review_task) do
              create(:qr_task, assigned_to: qr_user, parent: quality_review_organization_task)
            end
            let!(:task) { create(:ama_judge_assign_task, assigned_to: judge, parent: quality_review_task) }

            it "should not create a new QR task" do
              expect(QualityReviewTask.count).to eq(2)
              expect(quality_review_task.status).to eq("on_hold")

              post :complete, params: { task_id: task.id, tasks: params }
              expect(response.status).to eq 200

              expect(QualityReviewTask.count).to eq(2)

              expect(quality_review_task.reload.status).to eq("assigned")
            end
          end
        end
      end
    end
  end

  context "Legacy appeal" do
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
              "document_id": "M1234567.1234",
              "overtime": true,
              "note": "something"
            }
          end
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "M1234567.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)
          end
        end

        context "when all parameters are present to create Draft Decision" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["DRAFT_DECISION"],
              "reviewing_judge_id": judge.id,
              "work_product": "Decision",
              "document_id": "12345678.1234",
              "overtime": true,
              "note": "something",
              "issues": [{ "disposition": "3", "id": vacols_issue_remanded.issseq,
                           "remand_reasons": [{ "code": "AB", "post_aoj": true }] },
                         { "disposition": "1", "id": vacols_issue_allowed.issseq }]
            }
          end
          let!(:bva_dispatch_task_count_before) { BvaDispatchTask.count }

          it "should be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["document_id"]).to eq "12345678.1234"
            expect(response_body["task"]["overtime"]).to eq true
            expect(response_body["task"]["note"]).to eq "something"
            expect(response_body.keys).to include "issues"
            expect(bva_dispatch_task_count_before).to eq(BvaDispatchTask.count)
          end
        end

        context "when some required parameters are not present" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
              "work_product": "OMO - IME",
              "overtime": true,
              "note": "something"
            }
          end

          it "should not be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["title"]).to eq "Record is invalid"
            expect(response_body["errors"].first["detail"])
              .to eq "Reviewing judge can't be blank, Document ID can't be blank"
          end
        end

        context "when document_id is in the wrong format" do
          let(:params) do
            {
              "type": "AttorneyCaseReview",
              "document_id": "123456789.1234",
              "document_type": Constants::APPEAL_DECISION_TYPES["OMO_REQUEST"],
              "work_product": "OMO - IME",
              "overtime": true,
              "note": "something"
            }
          end

          it "should not be successful" do
            post :complete, params: { task_id: task_id, tasks: params }
            response_body = JSON.parse(response.body)

            expect(response.status).to eq 400
            expect(response_body["errors"].first["title"]).to eq "Record is invalid"
            expect(response_body["errors"].first["detail"])
              .to eq "Document ID of type IME must be in one of these formats: M1234567.123 or M1234567.1234, " \
                      "Reviewing judge can't be blank"
            expect(AttorneyCaseReview.count).to eq 0
          end
        end
      end

      context "Judge Case Review" do
        before do
          User.stub = judge
          # Do not select the case for quaility review
          allow_any_instance_of(JudgeCaseReview).to receive(:rand).and_return(probability + probability)
        end

        let(:probability) { JudgeCaseReview::QUALITY_REVIEW_SELECTION_PROBABILITY }
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
            expect(QueueRepository).to receive(:sign_decision_or_create_omo!).and_return(true)
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)
            expect(response_body["task"]["location"]).to eq "omo_office"
          end
        end

        context "when no access to the legacy task" do
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
              "issues": [{ "disposition": "1", "id": vacols_issue_remanded.issseq },
                         { "disposition": "3", "id": vacols_issue_allowed.issseq }]
            }
          end

          it "should not be successful" do
            allow_any_instance_of(User).to receive(:fail_if_no_access_to_legacy_task!)
              .and_raise(Caseflow::Error::UserRepositoryError, message: "No access")
            expect(Raven).to_not receive(:capture_exception)
            post :complete, params: { task_id: task_id, tasks: params }
            expect(response.status).to eq 400
            response_body = JSON.parse(response.body)
            expect(response_body["errors"].first["detail"]).to eq "No access"
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
              "issues": [{ "disposition": "1", "id": vacols_issue_remanded.issseq },
                         { "disposition": "3", "id": vacols_issue_allowed.issseq,
                           "remand_reasons": [{ "code": "AB", "post_aoj": true }] }]
            }
          end

          it "should be successful" do
            expect(QueueRepository).to receive(:sign_decision_or_create_omo!).and_return(true)
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
            expect(VACOLS::CaseIssue.where(
              isskey: vacols_case.bfkey, issseq: vacols_issue_remanded.issseq
            ).first.issdc).to eq "1"
            expect(VACOLS::CaseIssue.where(
              isskey: vacols_case.bfkey, issseq: vacols_issue_allowed.issseq
            ).first.issdc).to eq "3"
          end
        end
      end
    end
  end
end
