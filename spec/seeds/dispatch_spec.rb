# frozen_string_literal: true

describe Seeds::Dispatch do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      # to do: these are expensive to run, esp Facols.
      #Seeds::Users.new.seed!
      puts "start facols seed #{Time.zone.now}"
      Seeds::Facols.new.seed!
      puts "end facols seed #{Time.zone.now}"
    end

    it "creates all kinds of dispatch seeds" do
      expect { subject }.to_not raise_error
    end
  end
end     
