# frozen_string_literal: true

describe MailRequestJob do
  let!(package) { VbmsCommunicationPackage.create!(comm_package_name: "Jonah", created_at: DateTime.now, updated_at: DateTime.now) }
  context "successful " do
    subject { MailRequestJob.perform(package) }
    it "changes package status to success" do
      subject
      expect(package.status).to eq("success")
    end
    it "creates distribution" do
    end
  end
end
