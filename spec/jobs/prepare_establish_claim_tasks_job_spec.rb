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
        document_id: "123C"
      )] }
    }
    @task_one = EstablishClaim.create(appeal: @appeal_one)
    @task_two = EstablishClaim.create(appeal: @appeal_two)
  end

  context ".perform" do
    it "prepares the correct tasks" do
      expect(EstablishClaim.where(aasm_state: "unprepared").count).to eq(2)
      PrepareEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.where(aasm_state: "unassigned").count).to eq(1)
      expect(EstablishClaim.where(aasm_state: "unprepared").count).to eq(1)
    end
  end
end
