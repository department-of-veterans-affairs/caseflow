# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_exporter.rb"
require "helpers/intake_renderer.rb"
require "helpers/hearing_renderer.rb"

describe ExplainController, :all_dbs, type: :controller do
  include TaskHelpers

  describe "GET explain/appeals/:appeal_id" do
    let(:user_roles) { ["System Admin"] }
    before do
      User.authenticate!(roles: user_roles)
    end

    context ".json request for a legacy appeal" do
      let(:user) { create(:user) }
      let(:role) { :judge_role }
      let!(:staff_record) { create(:staff, role, sdomainid: user.css_id) }
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user, document_id: "NONE")) }
      subject { get :show, params: { appeal_id: appeal.vacols_id }, as: response_format }
      context ".json request" do
        let(:response_format) { :json }
        it "returns 'unsupported' string" do
          subject
          expect(JSON.parse(response.body)).to eq "(LegacyAppeals are not yet supported)"
        end
      end
      context ".text request" do
        let(:response_format) { :text }
        it "returns a minimal task tree" do
          subject
          expect(response.body).to include "LegacyAppeal #{appeal.id}"
          expect(response.body).to include "JudgeLegacyDecisionReviewTask"
          expect(response.body).to match(/assigned_to:.*User id: #{user.id}/)
        end
      end
    end

    let(:veteran) { create(:veteran, file_number: "111447777", middle_name: "Middle") }
    let(:appeal) do
      create(:appeal,
             :advanced_on_docket_due_to_motion,
             :with_schedule_hearing_tasks,
             :with_post_intake_tasks,
             veteran: veteran)
    end

    let(:response_format) { :json }
    let(:appeal_id) { appeal.uuid }
    subject { get :show, params: { appeal_id: appeal_id }, as: response_format }

    context "user is not a System Admin" do
      let(:user_roles) { [] }
      context "user is not in eligible organization" do
        before do
          Bva.singleton.add_user(current_user)
        end
        it "returns error message" do
          subject
          expect(response.response_code).to eq 403
          json_body = JSON.parse(response.body)
          expect(json_body["errors"].first["title"]).to eq "Additional access needed"
        end
      end
      context "user is in the BoardProductOwners organization" do
        before do
          BoardProductOwners.singleton.add_user(current_user)
        end
        it "allows access" do
          subject
          expect(response.response_code).to eq 200
          json_body = JSON.parse(response.body)
          expect(json_body["errors"]).to eq nil
          expect(json_body["appeals"].first["uuid"]).to eq appeal.uuid
        end
      end
      context "user is in the CaseflowSupport organization" do
        before do
          CaseflowSupport.singleton.add_user(current_user)
        end
        it "allows access" do
          subject
          expect(response.response_code).to eq 200
          json_body = JSON.parse(response.body)
          expect(json_body["errors"]).to eq nil
          expect(json_body["appeals"].first["uuid"]).to eq appeal.uuid
        end
      end
    end

    context ".json request" do
      let(:response_format) { :json }
      it "returns valid JSON tree" do
        subject
        json_body = JSON.parse(response.body)
        expect(json_body.keys).to include("metadata", "appeals", "veterans", "tasks", "users", "organizations")
        expect(json_body["veterans"].first["file_number"]).not_to eq veteran.file_number
      end
    end

    context ".text request" do
      let(:response_format) { :text }
      it "returns plain text task tree and intake tree" do
        subject
        # task tree
        expect(response.body).to include "Appeal #{appeal.id}"
        expect(response.body).to include "RootTask"
        expect(response.body).to include "HearingTask"
        expect(response.body).to include "ScheduleHearingTask"

        # intake render output
        expect(response.body).to include "VeteranClaimant"
        expect(response.body).to include "breadcrumbs:"
        expect(response.body).to include "Veteran #{appeal.veteran.id}"

        # hearing render output
        sched_hearing_task_id = appeal.tasks.of_type(:ScheduleHearingTask).first.id
        expect(response.body).to include "Unscheduled Hearing (SCH Task ID: #{sched_hearing_task_id}"
      end
    end

    context ".html (default) request" do
      let(:response_format) { :html }
      it "responds without error" do
        subject
        expect(response).to be_ok
      end
    end

    context "when show_pii is true" do
      subject { get :show, params: { appeal_id: appeal_id, show_pii: true }, as: response_format }
      context ".json request" do
        let(:response_format) { :json }
        it "returns valid JSON tree" do
          subject
          json_body = JSON.parse(response.body)
          expect(json_body.keys).to include("metadata", "appeals", "veterans", "tasks", "users", "organizations")
          expect(json_body["veterans"].first["file_number"]).to eq veteran.file_number
        end
      end
    end
  end
end
