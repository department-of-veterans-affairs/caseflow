# frozen_string_literal: true

describe Seeds::Hearings do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      Seeds::Users.new.seed! # to do: remove dependency
    end

    it "creates all kinds of hearings" do
      expect { subject }.to_not raise_error
      expect(Hearing.count).to eq(16)
    end
  end
end     
