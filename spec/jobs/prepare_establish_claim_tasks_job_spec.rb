# frozen_string_literal: true

describe PrepareEstablishClaimTasksJob, :all_dbs do
  FAILING_DECISION = "999"
  before do
    allow(VBMSService).to receive(:fetch_document_file) do |document|
      fail VBMS::ClientError, "Failure" if document.vbms_document_id == FAILING_DECISION

      "the decision file"
    end
  end

  let(:vacols_case_with_decision_document) do
    create(:case_with_decision, :status_complete, case_issues:
      [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:appeal_with_decision_document) do
    create(:legacy_appeal, vacols_case: vacols_case_with_decision_document)
  end

  let(:vacols_case_with_failed_document) do
    create(:case_with_old_decision, :status_complete, case_issues:
      [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:vacols_case_with_decision_that_will_fail) do
    create(:case_with_decision, :status_complete, case_issues:
      [create(:case_issue, :education, :disposition_allowed)])
  end

  let(:appeal_with_failed_document) do
    create(:legacy_appeal, vacols_case: vacols_case_with_failed_document)
  end

  let(:vacols_case_without_decision_document) do
    create(:case, :status_complete, case_issues:
        [create(:case_issue, :education, :disposition_allowed)], bfddec: 1.day.ago)
  end

  let(:appeal_without_decision_document) do
    create(:legacy_appeal, vacols_case: vacols_case_without_decision_document)
  end

  let!(:preparable_task) do
    EstablishClaim.create(appeal: appeal_with_decision_document)
  end

  let!(:failed_task) do
    EstablishClaim.create(appeal: appeal_with_failed_document)
  end

  let!(:not_preparable_task) do
    EstablishClaim.create(appeal: appeal_without_decision_document)
  end

  let!(:task_that_will_fail) do
    appeal = create(:legacy_appeal, vacols_case: vacols_case_with_decision_that_will_fail)
    appeal.decisions.first.update!(vbms_document_id: FAILING_DECISION)
    EstablishClaim.create(appeal: appeal)
  end

  context ".perform" do
    let(:filename) { Document::S3_BUCKET_NAME + "/" + appeal_with_decision_document.decisions.first.file_name }

    before do
      slack_service = double("slack")
      allow(slack_service).to receive(:send_notification) { @slack_called = true }
      allow(SlackService).to receive(:new) { slack_service }
    end

    it "prepares the correct tasks" do
      PrepareEstablishClaimTasksJob.perform_now

      expect(preparable_task.reload).to be_unassigned
      expect(failed_task.reload).to be_unprepared
      expect(not_preparable_task.reload).to be_unprepared

      # Validate that the decision content is cached in S3
      expect(S3Service.files[filename]).to eq("the decision file")
      expect(@slack_called).to eq(true)
    end
  end
end
