# frozen_string_literal: true

describe Seeds::Notifications do
  describe "#seed!" do
    before do
      Seeds::NotificationEvents.new.seed!
    end
    subject { described_class.new.seed! }
    it "seeds test notification data" do
      expect { subject }.to_not raise_error
    end
  end
end
