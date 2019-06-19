# frozen_string_literal: true

describe WarmBgsParticipantAddressCachesJob do
  context "default" do
    it "fetches all hearings and warms the Rails cache" do
      expect { WarmBgsParticipantAddressCachesJob.perform_now }.to_not raise_error
    end
  end
end
