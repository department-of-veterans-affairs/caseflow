# frozen_string_literal: true

RSpec.describe Hearings::VaBoxDownloadJob, type: :job do
  describe "#perform" do
    subject { described_class.perform_now }

    # before do
    #   allow(ExternalApi::VaBoxService).to receive(:new)
    #     .and_return(Fakes::VaBoxService.new)
    # end

    # # see data setup in Fakes::VaBoxService for expectations
    it "call job to download file and upload to S3 and create/update in transciption_table" do
      expect(subject).to eq(true)
    end

    # xit "fail to upload to S3" do
    # end

    # xit "fail to save in database" do
    # end
  end
end
