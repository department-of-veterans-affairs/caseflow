# frozen_string_literal: true

describe AmaAppealDispatch, :postgres do
  let(:user) { create(:user) }
  let(:appeal) { create(:appeal, :advanced_on_docket_due_to_age) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let(:poa_participant_id) { "600153863" }
  let(:bgs_poa) { instance_double(BgsPowerOfAttorney) }
  let(:params) do
    { appeal_id: appeal.id,
      appeal_type: "Appeal",
      citation_number: "A18123456",
      decision_date: Time.zone.now,
      redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx",
      file: "12345678" }
  end
  let(:mail_request) { instance_double(MailRequest) }
  let(:mail_request_job) { class_double(MailRequestJob) }

  before do
    BvaDispatch.singleton.add_user(user)
    BvaDispatchTask.create_from_root_task(root_task)
  end

  subject { AmaAppealDispatch.new(appeal: appeal, params: params, user: user, mail_request: mail_request).call }

  describe "#call" do
    it "stores current POA participant ID in the Appeals table" do
      allow(BgsPowerOfAttorney).to receive(:find_or_create_by_file_number)
        .with(appeal.veteran_file_number).and_return(bgs_poa)
      allow(bgs_poa).to receive(:participant_id).and_return(poa_participant_id)

      subject
      expect(appeal.reload.poa_participant_id).to eq poa_participant_id
    end

    context "document is associated with a mail request" do
      it "calls #perform_later on MailRequestJob" do
        expect(mail_request_job).to receive(:perform_later).with(params[:file], mail_request)
        subject
      end
    end

    context "document is not associated with a mail request" do
      let(:mail_request) { nil }
      it "does not call #perform_later on MailRequestJob" do
        expect(mail_request_job).to_not receive(:perform_later)
        subject
      end
    end

    context "document is not successfully uploaded to vbms" do
      it "does not call #perform_later on MailRequestJob" do
        allow(VBMSService).to receive(:upload_document_to_vbms_veteran).and_raise(StandardError)
        expect(mail_request_job).to_not receive(:perform_later)
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
