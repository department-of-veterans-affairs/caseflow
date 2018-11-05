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
  let(:nonpriority_ready_case) do
    create(:case,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: nonpriority_ready_case_docket_number))
  end

  let(:another_nonpriority_ready_case_docket_number) { "1801002" }
  let(:another_nonpriority_ready_case) do
    create(:case,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "83",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: another_nonpriority_ready_case_docket_number))
  end

  let(:nonpriority_unready_case) do
    create(:case,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "57",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago)
  end

  let(:priority_ready_case_docket_number) { "1801003" }
  let(:priority_ready_case) do
    create(:case,
           :aod,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "81",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago,
           folder: build(:folder, tinum: priority_ready_case_docket_number))
  end

  let(:priority_unready_case) do
    create(:case,
           :aod,
           bfac: "1",
           bfmpro: "ACT",
           bfcurloc: "55",
           bfdlocin: 1.hour.ago,
           bfdloout: 1.hour.ago)
  end

  context ".distribute_nonpriority_appeals" do
    context "genpop cases" do
      before do
        nonpriority_ready_case
        another_nonpriority_ready_case
        nonpriority_unready_case
        priority_ready_case
      end

      subject { VACOLS::CaseDocket.distribute_nonpriority_appeals(judge, nil, nil, 10) }

      it "distributes ready genpop cases" do
        expect(subject.count).to eq(2)
        expect(nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(another_nonpriority_ready_case.reload.bfcurloc).to eq(judge.vacols_uniq_id)
        expect(priority_ready_case.reload.bfcurloc).to eq("81")
      end
    end
  end

  context ".batch_update_vacols_location" do
    let(:conn) { VACOLS::CaseDocket.connection }
    let(:bfkeys) { (1..5).map(&:to_s) }
    let(:cases) do
      bfkeys.map do |bfkey|
        create(:case,
               bfkey: bfkey,
               bfcurloc: "77",
               bfdlocin: 1.hour.ago,
               bfdloout: 1.hour.ago)
      end
    end
    let(:initial_locations) do
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
      cases
      initial_locations
      VACOLS::CaseDocket.batch_update_vacols_location(conn, "99", bfkeys)
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
