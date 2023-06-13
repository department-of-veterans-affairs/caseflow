# frozen_string_literal: true

describe MailRequestJob do
  let!(veteran) { create(:veteran) }
  let!(appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
  let!(vbms_file) { create(:vbms_uploaded_document, appeal: appeal) }
  let!(mail_request) { create(:mail_request, participant_id: veteran.participant_id) }
  context "successful " do
    subject { MailRequestJob.perform(vbms_file, mail_request) }
    it "creates a new VbmsCommunicationPackage" do
      expect { subject }.to change { VbmsCommunicationPackage.count }.by(1)
    end
  end
  context "400 error in package request" do
    subject { MailRequestJob.perform(vbms_file, mail_request) }
    it "does not create a new VbmsCommunicationPackage"
    expect { subject }.to change { VbmsCommunicationPackage.count }.by(0)
  end
end
