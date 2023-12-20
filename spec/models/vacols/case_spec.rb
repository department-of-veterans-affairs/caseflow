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

  describe ".vacols_representatives" do
    let(:vacols_case) { create(:case) }
    subject { vacols_case.vacols_representatives }

    context "representative exists for this case in the vacols.rep table" do
      let!(:vacols_rep) { create(:representative, repkey: vacols_case.bfkey) }

      it "returns the representative associated with the case in the vacols.rep table" do
        expect(subject).to eq([vacols_rep])
      end
    end

    context "representative does not exist for this case in the vacols.rep table" do
      context "Veteran does not have any other cases in VACOLS" do
        it "returns no representatives for the case" do
          expect(subject).to eq([])
        end
      end

      context "Veteran has other cases in VACOLS" do
        context "Other cases have representatives for the Veteran" do
          let(:other_cases_with_valid_reps_count) { Random.rand(1..8) }
          before do
            other_cases_with_valid_reps_count.times.each do
              other_case = create(:case, correspondent: vacols_case.correspondent)
              random_valid_reptype = VACOLS::Representative::APPELLANT_REPTYPES.keys.sample
              create(
                :representative,
                repkey: other_case.bfkey,
                repcorkey: vacols_case.correspondent.stafkey,
                reptype: VACOLS::Representative::APPELLANT_REPTYPES[random_valid_reptype][:code]
              )
            end
          end

          it "returns the representatives associated with the Veteran's other cases" do
            expect(subject.length).to eq(other_cases_with_valid_reps_count)
          end
        end

        context "Other case has representative for a contested claim" do
          let(:other_case_with_contested_reps_count) { Random.rand(1..4) }
          before do
            other_case_with_contested_reps_count.times.each do
              other_case = create(:case, correspondent: vacols_case.correspondent)
              random_contested_reptype = VACOLS::Representative::CONTESTED_REPTYPES.keys.sample
              create(
                :representative,
                repkey: other_case.bfkey,
                repcorkey: vacols_case.correspondent.stafkey,
                reptype: VACOLS::Representative::CONTESTED_REPTYPES[random_contested_reptype][:code]
              )
            end
          end

          it "returns no representatives for the case" do
            expect(subject).to eq([])
          end
        end

        context "Other cases exist for normal representation as well as contested claim" do
          let(:other_cases_with_valid_reps_count) { Random.rand(1..8) }
          let(:other_case_with_contested_reps_count) { Random.rand(1..4) }
          before do
            other_cases_with_valid_reps_count.times.each do
              other_case = create(:case, correspondent: vacols_case.correspondent)
              random_valid_reptype = VACOLS::Representative::APPELLANT_REPTYPES.keys.sample
              create(
                :representative,
                repkey: other_case.bfkey,
                repcorkey: vacols_case.correspondent.stafkey,
                reptype: VACOLS::Representative::APPELLANT_REPTYPES[random_valid_reptype][:code]
              )
            end

            other_case_with_contested_reps_count.times.each do
              other_case = create(:case, correspondent: vacols_case.correspondent)
              random_contested_reptype = VACOLS::Representative::CONTESTED_REPTYPES.keys.sample
              create(
                :representative,
                repkey: other_case.bfkey,
                repcorkey: vacols_case.correspondent.stafkey,
                reptype: VACOLS::Representative::CONTESTED_REPTYPES[random_contested_reptype][:code]
              )
            end
          end

          it "returns only the representatives representing the Veteran and no contesting claimants" do
            expect(subject.length).to eq(other_cases_with_valid_reps_count)
          end
        end
      end
    end
  end
end
