describe VACOLS::CaseDocket do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let(:another_judge) { create(:user) }
  let!(:another_vacols_judge) { create(:staff, :judge_role, sdomainid: another_judge.css_id) }

  let(:nonpriority_ready_case_docket_number) { "1801001" }
  let!(:nonpriority_ready_case) do
    create(:case,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: nonpriority_ready_case_docket_number, titrnum: "1"))
  end

  let(:original_docket_number) { nonpriority_ready_case_docket_number }
  let!(:original) do
    create(:case,
           bfac: "1",
           bfmpro: "HIS",
           bfcurloc: "99",
           folder: build(:folder, tinum: original_docket_number, titrnum: "1"))
  end

  let(:another_nonpriority_ready_case_docket_number) { "1801002" }
  let!(:another_nonpriority_ready_case) do
    create(:case,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: another_nonpriority_ready_case_docket_number, titrnum: "1"))
  end

  let!(:nonpriority_unready_case) do
    create(:case,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "57",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago)
  end

  let(:aod_ready_case_docket_number) { "1801003" }
  let!(:aod_ready_case) do
    create(:case,
           :aod,
           bfac: "3",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: aod_ready_case_docket_number, titrnum: "1"))
  end

  let(:postcavc_ready_case_docket_number) { "1801004" }
  let!(:postcavc_ready_case) do
    create(:case,
           :aod,
           bfac: "7",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: postcavc_ready_case_docket_number, titrnum: "1"))
  end

  let!(:aod_unready_case) do
    create(:case,
           :aod,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "55",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago)
  end

  context ".distribute_nonpriority_appeals" do
    let(:genpop) { nil }
    let(:range) { nil }
    let(:limit) { 10 }

    subject { VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, genpop, range, limit) }

    it "distributes ready genpop cases" do
      expect(subject.count).to eq(2)
      expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
      expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
    end

    it "does not distribute non-ready or priority cases" do
      expect(nonpriority_unready_case.reload.bfcurloc).to eq("57")
      expect(aod_ready_case.reload.bfcurloc).to eq("81")
    end

    context "when limited" do
      let(:limit) { 1 }
      it "only distributes cases to the limit" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end
    end

    context "when range is specified" do
      let(:range) { 1 }
      it "only distributes cases within the range" do
        expect(subject.count).to eq(1)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
      end

      context "when the docket number is pre-y2k" do
        let(:another_nonpriority_ready_case_docket_number) { "9901002" }
        it "correctly orders the docket" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        end
      end
    end

    context "when a case is tied to a judge by a hearing on a prior appeal" do
      let(:hearing_judge) { judge.vacols_attorney_id }
      let!(:hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: original.bfkey,
               hearing_date: 5.days.ago,
               board_member: hearing_judge)
      end

      let!(:another_hearing) do
        create(:case_hearing,
               :disposition_held,
               folder_nr: another_nonpriority_ready_case.bfkey,
               hearing_date: 5.days.ago,
               board_member: another_judge.vacols_attorney_id)
      end

      context "when genpop is false" do
        let(:genpop) { false }
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is nil" do
        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when genpop is true" do
        let(:genpop) { true }
        it "does not distribute the case" do
          expect(subject.count).to eq(0)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq("81")
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end

      context "when the case has been made genpop" do
        let(:hearing_judge) { "1111" }
        let(:genpop) { true }

        before do
          nonpriority_ready_case.update(bfhines: "GP")
        end

        it "distributes the case" do
          expect(subject.count).to eq(1)
          expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
          expect(another_nonpriority_ready_case.reload.bfcurloc).to eq("83")
        end
      end
    end
  end

  context ".batch_update_vacols_location" do
    let(:conn) { VACOLS::CaseDocket.connection }
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
      VACOLS::CaseDocket.send(:batch_update_vacols_location, conn, "99", bfkeys)
    end

    context "brieff table" do
      subject { VACOLS::Case.find(bfkeys) }
      it "multiple cases moved" do
        expect(subject.all? { |c| c.bfcurloc == "99" && c.bfdlocin == Time.zone.now && c.bfdloout == Time.zone.now })
      end
    end

    context "old priorloc record" do
      subject { VACOLS::Priorloc.where(lockey: bfkeys, locstto: "77") }
      it "multiple cases checked in" do
        expect(subject.all? { |l| l.locdin == Time.zone.now && l.locstrcv == "DSUSER" && l.locexcep == "Y" })
      end
    end

    context "new priorloc record" do
      subject { VACOLS::Priorloc.where(lockey: bfkeys, locstto: "99") }
      it "multiple cases checked out" do
        expect(subject.count).to eq(5)
        expect(subject.all? { |l| l.locdout == Time.zone.now })
      end
    end
  end
end
