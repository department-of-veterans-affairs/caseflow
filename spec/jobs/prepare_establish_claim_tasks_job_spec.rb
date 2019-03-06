# frozen_string_literal: true

require "rails_helper"

describe PrepareEstablishClaimTasksJob do
  before do
    allow(VBMSService).to receive(:fetch_document_file) do |document|
      fail VBMS::ClientError, "Failure" if document.vbms_document_id == "2"

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

  context ".perform" do
    let(:filename) { Document::S3_BUCKET_NAME + "/" + appeal_with_decision_document.decisions.first.file_name }

    it "prepares the correct tasks" do
      PrepareEstablishClaimTasksJob.perform_now

      expect(preparable_task.reload).to be_unassigned
      expect(failed_task.reload).to be_unprepared
      expect(not_preparable_task.reload).to be_unprepared

      # Validate that the decision content is cached in S3
      expect(S3Service.files[filename]).to eq("the decision file")
    end
  end
end
