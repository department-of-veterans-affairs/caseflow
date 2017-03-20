require "rails_helper"

describe PrepareEstablishClaimTasksJob do
  before do
    expect(Appeal.repository).to receive(:fetch_document_file) { "the decision file" }
  end

  let!(:appeal_with_decision_document) do
    Generators::Appeal.create(
      vacols_record: Fakes::AppealRepository.appeal_remand_decided,
      documents: [Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)]
    )
  end

  let!(:appeal_without_decision_document) do
    Generators::Appeal.create(
      vacols_record: Fakes::AppealRepository.appeal_remand_decided,
      documents: [Generators::Document.build(type: "BVA Decision", received_at: 31.days.ago)]
    )
  end

  let!(:preparable_task) do
    EstablishClaim.create(appeal: appeal_with_decision_document)
  end

  let!(:not_preparable_task) do
    EstablishClaim.create(appeal: appeal_without_decision_document)
  end

  context ".perform" do
    let(:filename) { appeal_with_decision_document.decisions.first.file_name }

    it "prepares the correct tasks" do
      PrepareEstablishClaimTasksJob.perform_now

      expect(preparable_task.reload).to be_unassigned
      expect(not_preparable_task.reload).to be_unprepared

      # Validate that the decision content is cached in S3
      expect(S3Service.files[filename]).to eq("the decision file")
    end
  end
end
