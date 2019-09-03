# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe BvaDispatchTask, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  describe ".create_from_root_task" do
    context "when no root_task passed as argument" do
      it "throws an error" do
        expect { BvaDispatchTask.create_from_root_task(nil) }.to raise_error(NoMethodError)
      end
    end

    context "when valid root_task passed as argument" do
      let(:root_task) { create(:root_task) }
      before do
        OrganizationsUser.add_user_to_organization(create(:user), BvaDispatch.singleton)
      end

      it "should create a BvaDispatchTask assigned to a User with a parent task assigned to the BvaDispatch org" do
        parent_task = BvaDispatchTask.create_from_root_task(root_task)
        expect(parent_task.assigned_to.class).to eq(BvaDispatch)
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(parent_task.children.count).to eq 1
        child_task = parent_task.children.first
        expect(child_task.assigned_to.class).to eq User
        expect(child_task.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end

    context "when organization-level BvaDispatchTask already exists" do
      let(:root_task) { create(:root_task) }
      before do
        OrganizationsUser.add_user_to_organization(create(:user), BvaDispatch.singleton)
        BvaDispatchTask.create_from_root_task(root_task)
      end

      it "should raise an error" do
        expect { BvaDispatchTask.create_from_root_task(root_task) }.to raise_error(Caseflow::Error::DuplicateOrgTask)
      end
    end
  end

  describe ".outcode" do
    let(:user) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:the_case) { create(:case) }
    let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: the_case) }
    let(:citation_number) { "A18123456" }
    let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }
    let(:decision_date) { Date.new(1989, 12, 13).to_s }
    let(:params) do
      { appeal_id: root_task.appeal.external_id,
        citation_number: citation_number,
        decision_date: decision_date,
        file: file,
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx" }
    end
    let!(:request_issue) { create(:request_issue, decision_review: root_task.appeal) }
    let!(:di) { create(:decision_issue, decision_review: root_task.appeal, request_issues: [request_issue]) }

    before do
      OrganizationsUser.add_user_to_organization(user, BvaDispatch.singleton)
    end

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        allow(ProcessDecisionDocumentJob).to receive(:perform_later)

        BvaDispatchTask.outcode(root_task.appeal.reload, params, user)

        tasks = BvaDispatchTask.where(appeal: root_task.appeal, assigned_to: user)
        expect(tasks.length).to eq(1)
        task = tasks[0]
        expect(task.status).to eq("completed")
        expect(task.parent.status).to eq("completed")
        expect(task.root_task.status).to eq("completed")
        expect(request_issue.reload.closed_at).to eq(Time.zone.now)
        expect(request_issue.closed_status).to eq("decided")

        decision_document = DecisionDocument.find_by(appeal_id: root_task.appeal.id)

        expect(ProcessDecisionDocumentJob).to have_received(:perform_later)
          .with(decision_document.id).exactly(:once)
        expect(decision_document).to_not eq nil
        expect(decision_document.document_type).to eq "BVA Decision"
        expect(decision_document.source).to eq "BVA"
        expect(decision_document.submitted_at).to eq(Time.zone.now)
      end

      context "when legacy appeal" do
        let(:params_legacy) do
          p = params.clone
          p[:appeal_id] = legacy_appeal.id
          p
        end

        it "should not complete the BvaDispatchTask and the task assigned to the BvaDispatch org" do
          allow(ProcessDecisionDocumentJob).to receive(:perform_later)

          BvaDispatchTask.outcode(legacy_appeal, params_legacy, user)

          tasks = BvaDispatchTask.where(appeal: legacy_appeal, assigned_to: user)
          expect(tasks.length).to eq(0)

          decision_document = DecisionDocument.find_by(appeal_id: legacy_appeal.id)

          expect(ProcessDecisionDocumentJob).to have_received(:perform_later)
            .with(decision_document.id).exactly(:once)
          expect(decision_document).to_not eq nil
          expect(decision_document.document_type).to eq "BVA Decision"
          expect(decision_document.source).to eq "BVA"
          expect(decision_document.submitted_at).to eq(Time.zone.now)
        end
      end

      context "when decision_date is in the future" do
        let(:decision_date) { 1.day.from_now }

        it "sets a delay on the enqueued_job" do
          expect do
            BvaDispatchTask.outcode(root_task.appeal, params, user)
          end.to_not have_enqueued_job(ProcessDecisionDocumentJob)

          decision_document = DecisionDocument.find_by(appeal_id: root_task.appeal.id)
          expect(decision_document.submitted_at).to eq(
            decision_date - DecisionDocument::PROCESS_DELAY_VBMS_OFFSET_HOURS.hours
          )
          expect(decision_document.last_submitted_at).to eq(
            decision_date.to_date +
            DecisionDocument::PROCESS_DELAY_VBMS_OFFSET_HOURS.hours -
            DecisionDocument.processing_retry_interval_hours.hours + 1.minute
          )
        end
      end
    end
  end
end
