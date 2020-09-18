# frozen_string_literal: true

describe Seeds::Users do
  describe "#seed!" do
    subject { described_class.new.seed! }

    it "creates all kinds of users and organizations" do
      expect { subject }.to_not raise_error
      expect(User.count).to eq(79)
      expect(Organization.count).to eq(28)
    end
  end
end
