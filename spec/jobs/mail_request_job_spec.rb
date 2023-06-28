# frozen_string_literal: true

describe MailRequestJob do
  include ActiveJob::TestHelper

  let!(:current_user) { User.authenticate! }
  let!(:vbms_file) { create(:vbms_uploaded_document) }
  let!(:mail_request) { build(:mail_request) }

  context "successful " do
    it "creates a new VbmsCommunicationPackage" do
      mail_request.call
      mail_package = { distributions: [mail_request.to_json], copies: 1, created_by_id: 1 }

      expect do
        perform_enqueued_jobs { MailRequestJob.perform_later(vbms_file, mail_package) }
      end.to change { VbmsCommunicationPackage.count }.by(1)

      expect(
        find_comm_package_via_distribution_id(mail_request.vbms_distribution_id).status
      ).to eq("success")
    end
  end

  def find_comm_package_via_distribution_id(distro_id)
    distribution = VbmsDistribution.find(distro_id)

    VbmsCommunicationPackage.find(distribution.vbms_communication_package_id)
  end
end
