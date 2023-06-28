# frozen_string_literal: true

describe MailRequestJob do
  include ActiveJob::TestHelper

  let!(:current_user) { User.authenticate! }
  let!(:vbms_file) { create(:vbms_uploaded_document) }
  let!(:mail_request) { build(:mail_request) }

  let(:comm_package_uuid) { Fakes::PacmanService::COMMUNICATION_PACKAGE_UUID }
  let(:distribution_uuid) { Fakes::PacmanService::DISTRIBUTION_UUID }

  context "Successful execution of MailRequestJob" do
    it "Creates a new VbmsCommunicationPackage. The communication package and " \
      "distribution are given UUIDs from response" do
      mail_request.call
      mail_package = { distributions: [mail_request.to_json], copies: 1, created_by_id: 1 }

      expect do
        perform_enqueued_jobs { MailRequestJob.perform_later(vbms_file, mail_package) }
      end.to change { VbmsCommunicationPackage.count }.by(1)

      distribution = VbmsDistribution.find(mail_request.vbms_distribution_id)
      comm_package = find_comm_package_via_distribution_id(mail_request.vbms_distribution_id)

      expect(comm_package.status).to eq("success")

      expect(comm_package.uuid).to eq(comm_package_uuid)
      expect(distribution.uuid).to eq(distribution_uuid)
    end
  end

  context "Unsuccessful execution of MailRequestJob" do
    it "VbmsCommunicationPackage is not created. VbmsDistribution's UUID remains nil." do
      mail_request.call
      mail_package = { distributions: [mail_request.to_json], copies: 1, created_by_id: 1 }

      allow(PacmanService)
        .to receive(:send_communication_package_request)
        .and_raise(Caseflow::Error::PacmanApiError.new(code: 500, message: "Fake Error"))

      expect do
        perform_enqueued_jobs { MailRequestJob.perform_later(vbms_file, mail_package) }
      end.to change { VbmsCommunicationPackage.count }.by(1)

      distribution = VbmsDistribution.find(mail_request.vbms_distribution_id)
      comm_package = find_comm_package_via_distribution_id(mail_request.vbms_distribution_id)

      expect(comm_package).to be_nil
      expect(distribution.uuid).to be_nil
    end
  end

  def find_comm_package_via_distribution_id(distro_id)
    distribution = VbmsDistribution.find(distro_id)

    VbmsCommunicationPackage.find(distribution.vbms_communication_package_id)
  end
end
