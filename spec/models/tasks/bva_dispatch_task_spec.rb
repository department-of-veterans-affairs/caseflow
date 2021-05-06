# frozen_string_literal: true

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

    let(:root_task) { create(:root_task) }
    subject { BvaDispatchTask.create_from_root_task(root_task) }

    context "when valid root_task passed as argument" do
      before do
        BvaDispatch.singleton.add_user(create(:user))
      end

      it "should create a BvaDispatchTask assigned to a User with a parent task assigned to the BvaDispatch org" do
        parent_task = subject
        expect(parent_task.assigned_to.class).to eq(BvaDispatch)
        expect(parent_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(parent_task.children.count).to eq 1
        child_task = parent_task.children.first
        expect(child_task.assigned_to.class).to eq User
        expect(child_task.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end

    context "when organization-level BvaDispatchTask already exists" do
      before do
        BvaDispatch.singleton.add_user(create(:user))
        BvaDispatchTask.create_from_root_task(root_task)
      end

      it "should raise an error" do
        expect { subject }.to raise_error(Caseflow::Error::DuplicateOrgTask)
      end
    end

    context "when an open QualityReviewTask exists" do
      before do
        BvaDispatch.singleton.add_user(create(:user))
        create(:quality_review_task, parent: root_task)
      end

      it "should not create BvaDispatchTask" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".outcode" do
    let(:user) { create(:user) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:appeal) { create(:appeal, stream_type: stream_type) }
    let(:stream_type) { Constants.AMA_STREAM_TYPES.original }
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
    let!(:attorney) { create(:user) }
    let(:judge) { create(:user, full_name: "Judge User", css_id: "JUDGE_1") }

    before do
      BvaDispatch.singleton.add_user(user)
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

        before { create(:root_task, appeal: legacy_appeal) }

        it "should not complete the BvaDispatchTask but should close the root task" do
          allow(ProcessDecisionDocumentJob).to receive(:perform_later)

          BvaDispatchTask.outcode(legacy_appeal, params_legacy, user)

          tasks = BvaDispatchTask.where(appeal: legacy_appeal, assigned_to: user)
          expect(tasks.length).to eq(0)

          root_tasks = RootTask.where(appeal: legacy_appeal)
          expect(root_tasks.length).to eq(1)
          expect(root_tasks.first.status).to eq("completed")

          decision_document = DecisionDocument.find_by(appeal_id: legacy_appeal.id)

          expect(ProcessDecisionDocumentJob).to have_received(:perform_later)
            .with(decision_document.id).exactly(:once)
          expect(decision_document).to_not eq nil
          expect(decision_document.document_type).to eq "BVA Decision"
          expect(decision_document.source).to eq "BVA"
          expect(decision_document.submitted_at).to eq(Time.zone.now)
        end
      end

      context "when de_novo appeal stream" do
        let(:stream_type) { Constants.AMA_STREAM_TYPES.vacate }
        let!(:task) { create(:ama_judge_decision_review_task, appeal: appeal, assigned_to: judge) }
        let!(:attorney_task) { create(:ama_attorney_task, parent: task, assigned_to: attorney) }
        let!(:post_decision_motion) do
          create(:post_decision_motion,
                 appeal: appeal,
                 vacate_type: "vacate_and_de_novo",
                 task: task)
        end

        before do
          task.update!(status: "completed")
          attorney_task.update!(status: "completed")
        end

        it "should create de_novo appeal stream" do
          allow(ProcessDecisionDocumentJob).to receive(:perform_later)

          BvaDispatchTask.outcode(root_task.appeal, params, user)
          tasks = BvaDispatchTask.where(appeal: appeal, assigned_to: user)
          expect(tasks.length).to eq(1)

          de_novo_stream = Appeal.find_by(
            stream_docket_number: appeal.docket_number, stream_type: Constants.AMA_STREAM_TYPES.de_novo
          )

          expect(de_novo_stream).to_not be_nil
          request_issues = de_novo_stream.request_issues
          expect(request_issues.size).to eq(appeal.decision_issues.size)

          judge_task = JudgeDecisionReviewTask.find_by(assigned_to: judge, appeal: de_novo_stream)
          expect(judge_task).to_not be_nil
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

    context "when multiple BvaDispatchTask exist for user and appeal combination" do
      let!(:old_task) do
        task = BvaDispatchTask.create_from_root_task(root_task)
        task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        task
      end
      let!(:new_task) { BvaDispatchTask.create_from_root_task(root_task) }

      it "should throw an error" do
        expect { BvaDispatchTask.outcode(root_task.appeal.reload, params, user) }.to(raise_error) do |e|
          expect(e.class).to eq(Caseflow::Error::BvaDispatchTaskCountMismatch)
          expect(e.tasks.count).to eq(2)
          expect(e.user_id).to eq(user.id)
          expect(e.appeal_id).to eq(root_task.appeal.id)
        end
      end

      context "but one was cancelled" do
        before do
          old_task.children.first.update!(status: Constants.TASK_STATUSES.cancelled)
        end

        it "should not throw an error" do
          allow(ProcessDecisionDocumentJob).to receive(:perform_later)

          BvaDispatchTask.outcode(root_task.appeal.reload, params, user)

          tasks = BvaDispatchTask.not_cancelled.where(appeal: root_task.appeal, assigned_to: user)
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
      end
    end
  end

  describe "#available_actions" do
    let(:bva_d_task) { create(:bva_dispatch_task) }

    it "actions should not include 'Assign to Team'" do
      expect(bva_d_task.available_actions(bva_d_task.assigned_to))
        .not_to include(Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h)
    end

    it "actions should not include 'Mark Task Complete'" do
      expect(bva_d_task.available_actions(bva_d_task.assigned_to))
        .not_to include(Constants.TASK_ACTIONS.MARK_COMPLETE.to_h)
    end
  end
end
