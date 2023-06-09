# frozen_string_literal: true

describe UploadDocumentToVbmsJob, :postgres do
  describe ".perform" do
    let(:document) { create(:vbms_uploaded_document) }
    let(:service) { instance_double(UploadDocumentToVbms) }
    let(:user) { create(:user) }
    let(:mail_request) { instance_double(MailRequest) }
    let(:mail_request_job) { class_double(MailRequestJob) }

    let(:params) do
      { document_id: document.id,
        initiator_css_id: user.css_id,
        mail_request: mail_request }
    end

    subject { UploadDocumentToVbmsJob.perform_now(params) }

    it "calls #call on UploadDocumentToVbms instance" do
      expect(UploadDocumentToVbms).to receive(:new).with(document: document).and_return(service)
      expect(Raven).to receive(:user_context)
      expect(Raven).to receive(:extra_context)
      expect(service).to receive(:call)
      subject
    end

    context "document is associated with a mail request" do
      it "calls #perform_later on MailRequestJob" do
        expect(mail_request_job).to receive(:perform_later).with(document, mail_request)
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
