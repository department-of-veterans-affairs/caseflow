# frozen_string_literal: true

describe UpdateDocumentInVbmsJob, :postgres do
  describe ".perform" do
    let(:document) { create(:vbms_uploaded_document) }
    let(:service) { instance_double(UpdateDocumentInVbms) }
    let(:user) { create(:user) }

    subject { UpdateDocumentInVbmsJob.perform_now(document_id: document.id, initiator_css_id: user.css_id) }

    it "calls #call on UpdateDocumentInVbms instance" do
      expect(UpdateDocumentInVbms).to receive(:new).with(document: document).and_return(service)
      expect(Raven).to receive(:user_context)
      expect(Raven).to receive(:extra_context)
      expect(service).to receive(:call)
      subject
    end
  end
end
