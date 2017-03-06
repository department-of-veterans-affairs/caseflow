require "rails_helper"

describe PrepareEstablishClaimTasksJob do
  before do
    @appeal_one = Appeal.create(
      vacols_id: "123C",
      vbms_id: "VBMS_ID1"
    )
    @appeal_two = Appeal.create(
      vacols_id: "456D",
      vbms_id: "VBMS_ID2"
    )
    Fakes::AppealRepository.records = {
      "123C" => Fakes::AppealRepository.appeal_remand_decided,
      "456D" => Fakes::AppealRepository.appeal_remand_decided,
      "VBMS_ID1" => { documents: [Document.new(
        received_at: (Time.current - 7.days).to_date, type: "BVA Decision",
        vbms_document_id: "123C"
      )] }
    }
    @task_one = EstablishClaim.create(appeal: @appeal_one)
    @task_two = EstablishClaim.create(appeal: @appeal_two)

    expect(Appeal.repository).to receive(:fetch_document_file) { "the decision file" }
  end

  context ".perform" do
    let(:filename) { @task_one.appeal.decisions.first.file_name }

    it "prepares the correct tasks" do
      expect(EstablishClaim.where(aasm_state: "unprepared").count).to eq(2)
      PrepareEstablishClaimTasksJob.perform_now
      expect(@task_one.reload.unassigned?).to be_truthy
      expect(@task_two.reload.unprepared?).to be_truthy

      # Validate that the decision content is cached in S3
      expect(S3Service.files[filename]).to eq("the decision file")
    end
  end
end
