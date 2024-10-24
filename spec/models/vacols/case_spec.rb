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

  describe "Factory" do
    describe "legacy_aoj_appeal" do
      def check_common_assertions(new_case, original_case) # rubocop:disable Metrics/AbcSize
        expect(original_case.attributes.except!(*not_shared_brieff_attributes))
          .to eq(new_case.attributes.except!(*not_shared_brieff_attributes))
        expect(original_folder.attributes.except!(*not_shared_folder_attributes))
          .to eq(new_folder.attributes.except!(*not_shared_folder_attributes))

        expect(original_case.bfddec).to eq new_case.bfdpdcn
        expect(original_case.bfmpro).to eq "HIS"
        expect(original_case.bfcurloc).to eq "99"
        expect(new_case.bfmpro).to eq "ACT"
        expect(new_case.bfac).to eq "3"
        expect(new_case.bfcurloc).to eq "81"
      end

      let(:params) { {} }
      let(:traits) { [] }
      let!(:new_case) { create(:legacy_aoj_appeal, *traits, params) }
      let!(:original_case) { VACOLS::Case.where(bfcorlid: new_case.bfcorlid).where.not(bfkey: new_case.bfkey).first }
      let(:new_folder) { new_case.folder }
      let(:original_folder) { original_case.folder }

      let(:not_shared_brieff_attributes) do
        %w[bfkey bfmpro bfac bfcurloc bfddec bfdpdcn bfattid bfmemid bfdc bfdrodec bfcallup]
      end
      let(:not_shared_folder_attributes) do
        %w[tidrecv tidcls tiaduser tiadtime tikeywrd tiread2 tioctime tiocuser tidktime tidkuser ticknum]
      end

      describe "when provided no extra params", :aggregate_failures do
        it "creates a new and original appeal with correct shared attributes" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(VACOLS::Note.find_by(tsktknm: new_case.bfkey, tskactcd: "B")).to be nil
          expect(original_case.case_hearings.count).to eq 1
          expect(new_case.appeal_affinity).to be_truthy
        end
      end

      describe "when provided only AOD trait", :aggregate_failures do
        let(:traits) { [:aod] }

        it "creates a new and original appeal with correct shared attributes" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(VACOLS::Note.find_by(tsktknm: new_case.bfkey, tskactcd: "B")).to be_truthy
        end
      end

      describe "when provided only CAVC param", :aggregate_failures do
        let(:params) { { cavc: true } }

        it "creates a new and original appeal with correct shared attributes" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "7"
        end
      end

      describe "when provided AOD trait and CAVC param", :aggregate_failures do
        let(:traits) { [:aod] }
        let(:params) { { cavc: true } }

        it "creates a new and original appeal with correct shared attributes" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "7"
          expect(VACOLS::Note.find_by(tsktknm: new_case.bfkey, tskactcd: "B")).to be_truthy
        end
      end

      describe "when tied to is false" do
        let(:params) { { tied_to: false } }

        it "does not create a hearing on the original case" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(original_case.case_hearings.count).to eq 0
        end
      end

      describe "when appeal affinity is false" do
        let(:params) { { appeal_affinity: false } }

        it "does not create an appeal affinity" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(new_case.appeal_affinity).to be nil
        end
      end

      describe "when affinity start date is nil" do
        let(:params) { { affinity_start_date: nil } }

        it "creates appeal_affinity with nil start date" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(new_case.appeal_affinity.affinity_start_date).to be nil
        end
      end

      describe "when a judge and attorney are provided" do
        let(:params) { { judge: judge, attorney: attorney } }
        let(:judge) { create(:user, :judge, :with_vacols_judge_record).vacols_staff }
        let(:attorney) { create(:user, :with_vacols_attorney_record).vacols_staff }

        it "ties the original case/ hearing to the judge and attorney" do
          check_common_assertions(new_case, original_case)
          expect(original_case.bfac).to eq "1"
          expect(original_case.bfattid).to eq attorney.sattyid
          expect(original_case.bfmemid).to eq judge.sattyid
          expect(original_case.case_hearings.first.board_member).to eq judge.sattyid
        end
      end
    end
  end
end
