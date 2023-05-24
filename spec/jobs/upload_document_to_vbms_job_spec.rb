# frozen_string_literal: true

describe UploadDocumentToVbmsJob, :postgres do
  describe ".perform" do
    let(:document) { create(:vbms_uploaded_document) }
    let(:service) { instance_double(UploadDocumentToVbms) }
    let(:mail_request) { { name: "Jeff" } }
    # let(:mail_request_job) { instance_double(MailRequestJob) }
    let(:user) { create(:user) }

    subject { UploadDocumentToVbmsJob.perform_now(document_id: document.id, initiator_css_id: user.css_id, mail_request: mail_request) }

    it "calls #call on UploadDocumentToVbms instance" do
      expect(UploadDocumentToVbms).to receive(:new).with(document: document).and_return(service)
      expect(Raven).to receive(:user_context)
      expect(Raven).to receive(:extra_context)
      expect(service).to receive(:call)
      subject
    end

    it "does not queue a MailRequestJob without a MailRequest object present" do
      mail_request = nil
      expect(MailRequestJob).to_not receive(:perform)
      subject
    end

    it "queues a MailRequestJob if the document has been uploaded to vbms" do
      document.uploaded_to_vbms_at = Time.zone.now
      expect(MailRequestJob).to receive(:perform).with(document: document, mail_request: mail_request)
      subject
    end

    it "does not queue a MailRequestJob if the document has not been uploaded to vbms" do
      expect(MailRequestJob).to_not receive(:perform)
      subject
    end
  end
end
