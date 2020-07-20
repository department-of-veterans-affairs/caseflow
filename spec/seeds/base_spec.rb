# frozen_string_literal: true

class TestSeed < Seeds::Base
  def seed!
    create(:appeal)
  end
end

describe Seeds::Base do
  it "loads" do
    expect(subject).to be_a described_class
  end

  describe "#seed!" do
    subject { TestSeed.new.seed! }

    it "passes args to FactoryBot" do
      expect(subject).to be_a Appeal
    end
  end
end
