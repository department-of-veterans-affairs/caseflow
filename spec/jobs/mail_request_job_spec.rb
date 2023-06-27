# frozen_string_literal: true

describe MailRequestJob do
  let!(:user) { create(:user, id: 1) }
  let!(:vbms_file) { create(:vbms_uploaded_document) }
  let!(:mail_request) { build(:mail_request) }
  context "successful " do
    it "creates a new VbmsCommunicationPackage" do
      mail_request.call
      mail_package = { distributions: [mail_request.to_json], copies: 1, created_by_id: user.id }
      MailRequestJob.perform_now(vbms_file, mail_package)
      expect { MailRequestJob.perform_now(vbms_file, mail_package) }.to change { VbmsCommunicationPackage.count }.by(1)
      expect(VbmsCommunicationPackage.first.status).to eq("success")
    end
  end
  # context "400 error in package request" do
  #   it "does not create a new VbmsCommunicationPackage"
  #   expect { MailRequestJob.perform_now(vbms_file, nil) }.to change { VbmsCommunicationPackage.count }.by(0)
  # end
end
