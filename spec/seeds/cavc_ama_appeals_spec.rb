# frozen_string_literal: true

describe Seeds::CavcAmaAppeals do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      # Users and Facols are expensive to run, it'd be nice to
      # make Seeds::* less dependent
      Seeds::Users.new.seed!
      puts "start facols seed #{Time.zone.now}"
      Seeds::Facols.new.seed!
      puts "end facols seed #{Time.zone.now}"
      BvaDispatch.singleton.add_user(create(:user))
    end

    it "creates CAVC appeals" do
      expect { subject }.to_not raise_error
      expect(CavcTask.count).to eq(30)
      expect(Appeal.court_remand.count).to eq(30)
    end
  end
end
