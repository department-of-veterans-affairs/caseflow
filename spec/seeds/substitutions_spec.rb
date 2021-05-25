# frozen_string_literal: true

describe Seeds::Substitutions do
  describe "#seed!" do
    subject { described_class.new.seed! }

    before do
      Seeds::Users.new.seed!
      Seeds::Facols.new.local_vacols_staff!

      # Need a dispatch user for creating whole task trees
      BvaDispatch.singleton.add_user(User.find_or_create_by(css_id: "BVAGWHITE", station_id: "101"))
    end

    it "creates appeals ready for substitution" do
      expect { subject }.to_not raise_error

      expect(Appeal.where(veteran_file_number: 54_545_454).count).to eq(3)
    end
  end
end
