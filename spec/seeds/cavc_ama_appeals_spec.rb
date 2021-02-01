# frozen_string_literal: true

describe Seeds::CavcAmaAppeals do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      # to do: these are expensive to run, esp Facols.
      # make Seeds::Tasks less dependent on them.
      Seeds::Users.new.seed!
      puts "start facols seed #{Time.zone.now}"
      Seeds::Facols.new.seed!
      puts "end facols seed #{Time.zone.now}"
      puts "start tasks seed #{Time.zone.now}"
      Seeds::Tasks.new.seed!
      puts "end tasks seed #{Time.zone.now}"
    end

    it "creates CAVC appeals" do
      expect { subject }.to_not raise_error
      expect(CavcTask.count).to eq(30)
      expect(Appeal.court_remand.count).to eq(30)
    end
  end
end
