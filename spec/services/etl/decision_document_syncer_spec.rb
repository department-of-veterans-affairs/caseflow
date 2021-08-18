# frozen_string_literal: true

describe ETL::DecisionDocumentSyncer, :etl, :all_dbs do
  let(:appeal) { create(:appeal, :dispatched, :with_decision_issue) }
  let(:decision_document) { appeal.decision_documents.first }

  let(:attorney_task) { appeal.tasks.find_by(type: :AttorneyTask) }
  let(:attorney) { attorney_task.assigned_to }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

  let(:judge_task) { appeal.tasks.find_by(type: :JudgeDecisionReviewTask) }
  let(:judge) { judge_task.assigned_to }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let!(:attorney_case_review) { create(:attorney_case_review, task: attorney_task, attorney: attorney) }

  let!(:judge_case_review) do
    create(:judge_case_review, location: :bva_dispatch, task: judge_task, judge: judge, attorney: attorney)
  end

  let(:etl_build) { ETL::Build.create }

  describe "#call" do
    subject { described_class.new(etl_build: etl_build).call }

    context "a decision document for each appeal type" do
      # For Legacy appeal
      let(:legacy_appeal) { create(:legacy_appeal) }
      let!(:legacy_decision_document) { create(:decision_document, appeal: legacy_appeal) }
      let(:case_assignment) do
        OpenStruct.new(vacols_id: legacy_appeal.vacols_id,
                       date_due: 1.day.ago,
                       reassigned_to_judge_date: nil,
                       docket_date: nil,
                       created_at: 5.days.ago,
                       assigned_to_location_date: 3.days.ago,
                       assigned_to_attorney_date: nil,
                       document_id: "173341517.524",
                       assigned_by: OpenStruct.new(first_name: "Joe", last_name: "Schmoe"))
      end
      let(:created_at) { "2019-02-14" }
      before do
        judge.tap { |user| create(:staff, :judge_role, user: user) }
        attorney.tap { |user| create(:staff, :attorney_role, user: user) }

        case_assignment = double(
          vacols_id: legacy_appeal.vacols_id,
          assigned_by_css_id: attorney.css_id,
          assigned_to_css_id: judge.css_id,
          document_id: "02255-00000002",
          work_product: :draft_decision,
          created_at: created_at.to_date
        )
        allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(legacy_appeal.vacols_id)
          .and_return(case_assignment)
        allow(case_assignment).to receive(:valid_document_id?).and_return(true)

        JudgeCaseReview.create!(
          attorney: attorney,
          judge: judge,
          task_id: legacy_appeal.task_id_for_case_reviews,
          complexity: "easy",
          quality: "meets_expectations",
          location: :bva_dispatch,
          comment: "",
          factors_not_considered: [],
          areas_for_improvement: [],
          one_touch_initiative: false,
          positive_feedback: []
        )
      end
      it "syncs attributes" do
        expect(ETL::DecisionDocument.count).to eq(0)

        subject
        expect(ETL::DecisionDocument.count).to eq(2)

        expect(ETL::DecisionDocument.first.decision_document_created_at)
          .to be_within(1.second).of(decision_document.created_at)
      end
    end

    context "when associated with other ETL tables" do
      let(:connection) { ETL::Record.connection }
      before do
        ETL::UserSyncer.new(etl_build: etl_build).call
        ETL::DecisionIssueSyncer.new(etl_build: etl_build).call
        ETL::AttorneyCaseReviewSyncer.new(etl_build: etl_build).call
      end
      it "enables SQL joins" do
        subject
        expect(ETL::DecisionDocument.count).to eq(1)
        expect(ETL::DecisionIssue.count).to eq(2)

        # Paul Saindon's DecisionDocument query
        query = <<~SQL
          SELECT
            docs.citation_number AS "Citation nr.",
            docs.docket_number AS "Docket nr.",
            to_char(docs.decision_date, 'mm/dd/yy') AS "Decision Date",
            CONCAT(judge.sattyid, ' ', judge.full_name) AS "VLJ number and name",
            CONCAT(atty.sattyid, ' ', atty.full_name) AS "Attorney number and name",
            issue.disposition AS Disposition,
            issue.benefit_type AS "Program area desc",
            REPLACE(REPLACE(issue.description, CHR(13), ' '), CHR(10),'') AS "Issue code desc",
            REPLACE(REPLACE(issue.diagnostic_code, CHR(13), ' '), CHR(10), '') AS "Issue lev1 desc",
            '' AS "Issue lev2 desc",
            '' AS "Issue lev3 desc"
          FROM decision_documents AS docs
          LEFT JOIN decision_issues AS issue
            ON docs.appeal_id = issue.decision_review_id
            AND docs.appeal_type = issue.decision_review_type
          LEFT JOIN users AS judge
            ON judge.id = docs.judge_user_id
          LEFT JOIN users AS atty
            ON atty.id = docs.attorney_user_id
        SQL
        result = connection.exec_query(query).to_a
        expect(result.size).to eq ETL::DecisionDocument.count * ETL::DecisionIssue.count

        # Paul Saindon's D.O.C. query 1
        query = <<~SQL
          SELECT
            docs.appeal_id, docs.appeal_type,
            docs.docket_number AS "Docket nr.",
            to_char(docs.decision_date, 'mm/dd/yy') AS "Decision Date",
            to_char(judge_cr.review_updated_at, 'mm/dd/yy') AS "Judge Case Review updated",
            CONCAT(judge.sattyid, ' ', judge.full_name) AS "VLJ number and name",
            CONCAT(atty.sattyid, ' ', atty.full_name) AS "Attorney number and name",
            atty_cr.overtime AS "Attorney overtime",
            COUNT(CASE WHEN issues.disposition IN ('denied','remanded','allowed') THEN 1 ELSE null END) AS "ard_issues",
            COUNT(CASE WHEN issues.disposition IN ('denied','remanded','allowed') THEN null ELSE 1 END) AS "other_issues"
          FROM decision_documents AS docs
          LEFT JOIN decision_issues AS issues
            ON docs.appeal_id = issues.decision_review_id
            AND docs.appeal_type = issues.decision_review_type
            AND issues.issue_deleted_at IS NULL
          LEFT JOIN attorney_case_reviews AS atty_cr
            ON docs.appeal_id = atty_cr.appeal_id
            AND docs.appeal_type = atty_cr.appeal_type
          LEFT JOIN judge_case_reviews AS judge_cr
            ON docs.appeal_id = judge_cr.appeal_id
            AND docs.appeal_type = judge_cr.appeal_type
          LEFT JOIN users AS judge
            ON judge.id = docs.judge_user_id
          LEFT JOIN users AS atty
            ON atty.id = docs.attorney_user_id
          GROUP BY docs.appeal_id, docs.appeal_type,
            docs.docket_number, docs.decision_date,
            judge_cr.review_updated_at,
            judge.sattyid, judge.full_name,
            atty.sattyid, atty.full_name,
            atty_cr.overtime
        SQL
        result = connection.exec_query(query).to_a
        expect(result.size).to eq 1
        expect(result.first["ard_issues"]).to eq ETL::DecisionIssue.count
        expect(result.first["other_issues"]).to eq 0
      end
    end
  end
end
