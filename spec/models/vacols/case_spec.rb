# frozen_string_literal: true

describe VACOLS::Case, :all_dbs do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context ".batch_update_vacols_location" do
    let(:bfkeys) { (1..5).map(&:to_s) }
    let!(:cases) do
      bfkeys.map do |bfkey|
        create(:case,
               bfkey: bfkey,
               bfcurloc: "77",
               bfdlocin: 1.hour.ago,
               bfdloout: 1.hour.ago)
      end
    end
    let!(:initial_locations) do
      bfkeys.map do |bfkey|
        create(:priorloc,
               lockey: bfkey,
               locdout: 1.hour.ago,
               locdto: 1.hour.ago,
               locstto: "77",
               locstout: "USER1")
      end
    end

    before do
      VACOLS::Case.batch_update_vacols_location(LegacyAppeal::LOCATION_CODES[:closed], bfkeys)
    end

    context "brieff table" do
      subject { VACOLS::Case.find(bfkeys) }
      it "multiple cases moved" do
        expect(
          subject.all? do |c|
            c.bfcurloc == LegacyAppeal::LOCATION_CODES[:closed] \
              && c.bfdlocin == Time.zone.now \
              && c.bfdloout == Time.zone.now
          end
        )
      end
    end

    context "old priorloc record" do
      subject { VACOLS::Priorloc.where(lockey: bfkeys, locstto: "77") }
      it "multiple cases checked in" do
        expect(subject.all? { |l| l.locdin == Time.zone.now && l.locstrcv == "DSUSER" && l.locexcep == "Y" })
      end
    end

    context "new priorloc record" do
      subject { VACOLS::Priorloc.where(lockey: bfkeys, locstto: LegacyAppeal::LOCATION_CODES[:closed]) }
      it "multiple cases checked out" do
        expect(subject.count).to eq(5)
        expect(subject.all? { |l| l.locdout == Time.zone.now })
      end
    end
  end
end
