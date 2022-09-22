# frozen_string_literal: true

describe Seeds::NotificationEvents do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates the Notification Events" do
      expect { subject }.to_not raise_error
      expect(NotificationEvent.count).to eq(13)
    end
  end
end
