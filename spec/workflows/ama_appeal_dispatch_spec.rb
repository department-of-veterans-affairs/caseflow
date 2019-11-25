# frozen_string_literal: true

describe AmaAppealDispatch, :postgres do
  describe "#call" do
    it "stores current POA participant ID in the Appeals table" do
      user = create(:user)
      BvaDispatch.singleton.add_user(user)
      appeal = create(:appeal, :advanced_on_docket_due_to_age)
      root_task = create(:root_task, appeal: appeal)
      BvaDispatchTask.create_from_root_task(root_task)
      claimant = appeal.claimant
      poa_participant_id = "1234567"

      bgs_poa = instance_double(BgsPowerOfAttorney)
      allow(BgsPowerOfAttorney).to receive(:new)
        .with(claimant_participant_id: claimant.participant_id).and_return(bgs_poa)
      allow(bgs_poa).to receive(:participant_id).and_return(poa_participant_id)

      params = {
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        citation_number: "A18123456",
        decision_date: Time.zone.now,
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx",
        file: "12345678"
      }

      AmaAppealDispatch.new(appeal: appeal, params: params, user: user).call

      expect(appeal.reload.poa_participant_id).to eq poa_participant_id
    end
  end
end
