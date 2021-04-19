# frozen_string_literal: true

describe Seeds::Hearings do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      Seeds::Users.new.seed! # to do: remove dependency
    end

    it "creates all kinds of hearings", :aggregate_failures do
      expect { subject }.to_not raise_error
      expect(Hearing.count).to eq(294) # Seeds::Users.new.seed! creates 4 hearings
      expect(LegacyHearing.count).to eq(290)
      expect(HearingDay.count).to eq(394) # Seeds::Users.new.seed! creates 4 hearing days
    end
  end
end
