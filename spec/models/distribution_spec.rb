describe Distribution do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:css_id) { "BVARZIEMANN1" }
  let(:judge) { create(:user, css_id: css_id) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: css_id) }

  context "distribute" do
    subject { Distribution.create(judge: judge) }

    let!(:priority_cases) do
      (1..15).map do |i|
        create(:case,
               :aod,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:nonpriority_cases) do
      (16..100).map do |i|
        create(:case,
               bfd19: 1.year.ago,
               bfac: "1",
               bfmpro: "ACT",
               bfcurloc: "81",
               bfdloout: i.days.ago,
               folder: build(:folder, tinum: "1801#{format('%03d', i)}", titrnum: "123456789S"))
      end
    end

    let!(:same_judge_priority_hearings) do
      priority_cases[0..1].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:same_judge_nonpriority_hearings) do
      nonpriority_cases[29..33].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: judge.vacols_attorney_id)
      end
    end

    let!(:other_judge_hearings) do
      nonpriority_cases[2..27].map do |appeal|
        create(:case_hearing,
               :disposition_held,
               folder_nr: appeal.bfkey,
               hearing_date: 1.month.ago,
               board_member: "1234")
      end
    end

    it "correctly distributes cases to the judge" do
      expect(subject.valid?).to eq(true)
      expect(subject.completed_at).to eq(Time.zone.now)
      expect(subject.statistics["acting_judge"]).to eq(false)
      expect(subject.statistics["batch_size"]).to eq(15)
      expect(subject.statistics["total_batch_size"]).to eq(45)
      expect(subject.statistics["priority_count"]).to eq(15)
      expect(subject.distributed_cases.count).to eq(15)
      expect(subject.distributed_cases.first.docket).to eq("legacy")
      expect(subject.distributed_cases.first.ready_at).to eq(2.days.ago.beginning_of_day)
      expect(subject.distributed_cases.where(priority: true).count).to eq(5)
      expect(subject.distributed_cases.where(genpop: true).count).to eq(8)
      expect(subject.distributed_cases.where(priority: true, genpop: false).count).to eq(2)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "no").count).to eq(1)
      expect(subject.distributed_cases.where(priority: false, genpop_query: "any").map(&:docket_index).max).to eq(35)
    end

    context "when the judge is acting" do
      let(:css_id) { "RANDO" }
      let!(:vacols_judge) { create(:staff, :attorney_judge_role, sdomainid: css_id) }

      it "correctly distributes cases to the acting judge" do
        expect(subject.valid?).to eq(true)
        expect(subject.statistics["acting_judge"]).to eq(true)
        expect(subject.statistics["batch_size"]).to eq(10)
        expect(subject.distributed_cases.count).to eq(7)
        expect(subject.distributed_cases.where(genpop: false).count).to eq(7)
      end
    end
  end

  context "validations" do
    subject { Distribution.create(judge: user) }

    let(:user) { judge }

    context "when the user is not a judge in VACOOLS" do
      let(:user) { create(:user) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end

    context "when the judge has an unassigned legacy appeal" do
      let!(:legacy_appeal) { create(:case, bfcurloc: vacols_judge.slogid) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end

    context "when the judge has an unassigned AMA appeal" do
      let!(:task) { create(:ama_judge_task, assigned_to: judge) }

      it "does not validate" do
        expect(subject.errors.details).to have_key(:judge)
      end
    end
  end
end
