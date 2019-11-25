# frozen_string_literal: true

RSpec.describe IssuesController, :all_dbs, type: :controller do
  let!(:user) { User.authenticate!(roles: ["System Admin"]) }
  let(:case_issue) { nil }
  let(:appeal) do
    create(:legacy_appeal, vacols_case: create(
      :case,
      :assigned,
      user: user,
      bfkey: "354672",
      case_issues: case_issue ? [case_issue] : []
    ))
  end

  before do
    allow(Raven).to receive(:capture_exception)
  end

  describe "POST appeals/:appeal_id/issues" do
    context "when all parameters are present" do
      let(:params) do
        {
          program: "02",
          issue: "15",
          level_1: "03",
          level_2: "5252",
          level_3: nil,
          note: "test"
        }
      end

      it "should be successful" do
        post :create, params: { appeal_id: appeal.vacols_id, issues: params }
        expect(response.status).to eq 201
        response_body = JSON.parse(response.body)["issues"].first
        expect(response_body["codes"]).to eq %w[03 5252]
        expect(response_body["labels"]).to eq ["Compensation",
                                               "Service connection",
                                               "All Others",
                                               "Thigh, limitation of flexion of"]
        expect(response_body["vacols_sequence_id"]).to eq 1
        expect(response_body["note"]).to eq "test"
      end
    end

    context "when current user does not have access" do
      let(:params) do
        {
          program: "02",
          issue: "15",
          level_1: "03",
          level_2: "5252",
          level_3: nil,
          note: "test"
        }
      end

      it "should not be successful" do
        post :create, params: { appeal_id:
          create(:legacy_appeal, vacols_case: create(:case)).vacols_id,
                                issues: params }
        expect(Raven).to_not receive(:capture_exception)
        expect(response.status).to eq 400
        response_body = JSON.parse(response.body)["errors"].first["detail"]
        expect(response_body).to match(/cannot modify appeal/)
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :create, params: { appeal_id: "3456789", issues: {} }
        expect(response.status).to eq 404
      end
    end

    context "when Caseflow::Error::IssueRepositoryError" do
      let(:params) do
        {
          program: "01",
          issue: "02",
          level_1: "03",
          level_2: "04",
          level_3: nil,
          note: "test"
        }
      end

      it "should return bad request" do
        post :create, params: { appeal_id: appeal.vacols_id, issues: params }
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(Raven).to_not receive(:capture_exception)
        expect(error["title"]).to include "Combination of VACOLS Issue codes is invalid"
        expect(error["detail"]).to include "Combination of VACOLS Issue codes is invalid"
      end
    end

    context "when ActiveRecord::RecordInvalid" do
      let(:params) do
        {
          program: "02",
          issue: "15",
          level_1: "03",
          level_2: "5252",
          level_3: nil,
          note: "test"
        }
      end

      it "should return bad request" do
        allow(VACOLS::CaseIssue).to receive(:create_issue!).and_raise(ActiveRecord::RecordInvalid)
        post :create, params: { appeal_id: appeal.vacols_id, issues: params }
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(error["title"]).to eq "ActiveRecord::RecordInvalid"
      end
    end
  end

  describe "PATCH appeals/:appeal_id/issues/:vacols_sequence_id" do
    let(:case_issue) { create(:case_issue) }

    context "when all parameters are present" do
      let(:params) do
        {
          program: "02",
          issue: "15",
          level_1: "03",
          level_2: "5252",
          level_3: nil,
          note: "test"
        }
      end

      let(:result_params) do
        {
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: case_issue.issseq,
          issue_attrs: params.merge(vacols_user_id: "DSUSER").stringify_keys
        }
      end

      it "should be successful" do
        post :update, params: { appeal_id: appeal.vacols_id, vacols_sequence_id: case_issue.issseq, issues: params }
        expect(response.status).to eq 200
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :update, params: { appeal_id: 45_545_454, vacols_sequence_id: case_issue.issseq, issues: {} }
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
          level_3: nil,
          note: "test"
        }
      end

      let(:result_params) do
        {
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: case_issue.issseq,
          issue_attrs: params.merge(vacols_user_id: "DSUSER").stringify_keys
        }
      end

      it "should not be successful" do
        post :update, params: { appeal_id: appeal.vacols_id, vacols_sequence_id: case_issue.issseq, issues: params }
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(Raven).to_not receive(:capture_exception)
        expect(error["title"]).to include "Combination of VACOLS Issue codes is invalid"
        expect(error["detail"]).to include "Combination of VACOLS Issue codes is invalid"
      end
    end
  end

  describe "DELETE appeals/:appeal_id/issues/:vacols_sequence_id" do
    let(:case_issue) { create(:case_issue) }

    context "when deleted successfully" do
      let(:result_params) do
        {
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: case_issue.issseq
        }
      end
      it "should be successful" do
        post :destroy, params: { appeal_id: appeal.vacols_id, vacols_sequence_id: case_issue.issseq }
        expect(response.status).to eq 200
      end
    end

    context "when appeal is not found" do
      it "should return not found" do
        post :destroy, params: { appeal_id: 45_545_454, vacols_sequence_id: case_issue.issseq, issues: {} }
        expect(response.status).to eq 404
      end
    end

    context "when there is an error" do
      let(:result_params) do
        {
          vacols_id: appeal.vacols_id,
          vacols_sequence_id: case_issue.issseq
        }
      end
      it "should not be successful" do
        post :destroy, params: { appeal_id: appeal.vacols_id, vacols_sequence_id: case_issue.issseq + 1 }
        expect(response.status).to eq 400
        error = JSON.parse(response.body)["errors"].first
        expect(Raven).to_not receive(:capture_exception)
        expect(error["title"]).to include "Cannot find issue"
        expect(error["detail"]).to include "Cannot find issue"
      end
    end
  end
end
