# frozen_string_literal: true

describe Seeds::Education do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates the Executive Management Office" do
      expect { subject }.to_not raise_error
      expect(EducationEmo.count).to eq(1)
    end

    it "creates all Regional Processing Offices" do
      expect { subject }.to_not raise_error
      expect(EducationRpo.count).to eq(3)
    end
  end
end
