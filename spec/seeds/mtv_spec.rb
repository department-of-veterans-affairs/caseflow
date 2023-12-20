# frozen_string_literal: true

describe Seeds::MTV do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      Seeds::Users.new.seed! # TOODO
      Seeds::Facols.new.local_vacols_staff! # to do:
    end

    it "creates all kinds of motions to vacate" do
      expect { subject }.to_not raise_error
      expect(BvaDispatchTask.count).to eq(86)
    end
  end
end
