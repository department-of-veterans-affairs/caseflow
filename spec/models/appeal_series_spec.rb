# frozen_string_literal: true

describe AppealSeries, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  before do
    allow(AppealRepository).to receive(:latest_docket_month) { 11.months.ago.to_date.beginning_of_month }
    allow(AppealRepository).to receive(:regular_non_aod_docket_count) { 123_456 }
    allow(AppealRepository).to receive(:docket_counts_by_month) do
      (1.year.ago.to_date..Time.zone.today).map { |d| Date.new(d.year, d.month, 1) }.uniq.each_with_index.map do |d, i|
        {
          "year" => d.year,
          "month" => d.month,
          "cumsum_n" => i * 10_000 + 3456,
          "cumsum_ready_n" => i * 5000 + 3456
        }
      end
    end
  end

  let(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [latest_appeal] }
  let(:latest_appeal) do
    build(:legacy_appeal, vacols_case: latest_case)
  end

  let(:latest_case) do
    create(
      :case,
      :assigned,
      :certified,
      bfdnod: nod_date,
      bfdsoc: soc_date,
      bfssoc1: ssoc_date1,
      bfssoc2: ssoc_date2,
      bfd19: form9_date,
      certification_date: certification_date,
      bfdrodec: 1.day.ago,
      bfddec: decision_date,
      bfdc: disposition,
      bfcurloc: location_code,
      bfmpro: status,
      bfac: type,
      bfso: "F",
      case_issues: latest_appeal_issues
    )
  end

  let(:latest_appeal_issues) { [] }
  let(:type) { "1" }
  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:ssoc_date1) { nil }
  let(:ssoc_date2) { nil }
  let(:form9_date) { 1.day.ago }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }
  let(:location_code) { "77" }
  let(:status) { "ADV" }

  # Sometimes there are empty issues in VACOLS; we should ignore these issues
  before do
    latest_appeal.issues << Generators::Issue.build(
      codes: [],
      labels: [],
      disposition: nil,
      close_date: nil
    )
  end

  context "#vacols_ids" do
    subject { series.vacols_ids }

    let(:appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, :status_active, bfkey: "1234567", bfdloout: 1.day.ago)),
        create(:legacy_appeal, vacols_case: create(:case, :status_active, bfkey: "7654321", bfdloout: 2.days.ago))
      ]
    end

    it { is_expected.to eq %w[1234567 7654321] }
  end

  context "#latest_appeal" do
    subject { series.latest_appeal.vacols_id }

    context "when there are multiple active appeals" do
      let(:appeals) do
        [
          create(:legacy_appeal, vacols_case: create(:case, :status_active, bfkey: "1234567", bfdloout: 1.day.ago)),
          create(:legacy_appeal, vacols_case: create(:case, :status_active, bfkey: "7654321", bfdloout: 2.days.ago))
        ]
      end

      it { is_expected.to eq "1234567" }
    end

    context "when there are no active appeals" do
      let(:appeals) do
        [
          create(:legacy_appeal, vacols_case: create(:case, :status_complete, bfkey: "1234567", bfdloout: 1.day.ago)),
          create(:legacy_appeal, vacols_case: create(:case, :status_complete, bfkey: "7654321", bfdloout: 2.days.ago))
        ]
      end

      it "handles nil decision_date comparison" do
        allow(appeals.first).to receive(:decision_date) { nil }
        allow(appeals.last).to receive(:decision_date) { Time.zone.now }

        expect(series.latest_appeal).to_not be_nil
      end

      it { is_expected.to eq "1234567" }
    end
  end

  context "#location" do
    subject { series.location }

    context "when it is in advance status" do
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in remand status" do
      let(:status) { "REM" }
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in any other status" do
      let(:status) { "HIS" }
      it { is_expected.to eq(:bva) }
    end
  end

  context "#program" do
    subject { series.program }

    let(:latest_appeal_issues) { [create(:case_issue, :compensation)] }

    context "when there is only one program on appeal" do
      it { is_expected.to eq(:compensation) }
    end

    context "when there are multiple programs on appeal" do
      let(:latest_appeal_issues) do
        [create(:case_issue, :compensation), create(:case_issue, issprog: "07", isscode: "07", isslev1: "02")]
      end

      it { is_expected.to eq(:multiple) }
    end
  end

  context "#aoj" do
    subject { series.aoj }

    context "when the first issue on appeal has no aoj" do
      let(:latest_appeal_issues) do
        [create(:case_issue), create(:case_issue, issprog: "10", isscode: "01", isslev1: "02")]
      end

      it { is_expected.to eq(:vba) }
    end
  end

  context "#status" do
    subject { series.status }

    context "when it is in advance status" do
      it { is_expected.to eq(:pending_certification) }

      context "and it has received one or more ssocs" do
        let(:ssoc_date1) { 1.day.ago }
        it { is_expected.to eq(:pending_certification_ssoc) }
      end

      context "and it has been certified" do
        let(:certification_date) { 1.day.ago }
        it { is_expected.to eq(:on_docket) }
      end

      context "and it has no form 9" do
        let(:form9_date) { nil }
        it { is_expected.to eq(:pending_form9) }

        context "and it has no soc" do
          let(:soc_date) { nil }
          it { is_expected.to eq(:pending_soc) }
        end
      end
    end

    context "when it is in active status" do
      let(:status) { "ACT" }
      it { is_expected.to eq(:decision_in_progress) }

      context "and it is in location 49" do
        let(:location_code) { "49" }
        it { is_expected.to eq(:stayed) }
      end

      context "and it is in location 55" do
        let(:location_code) { "55" }
        it { is_expected.to eq(:at_vso) }
      end

      context "and it is in location 20" do
        let(:location_code) { "20" }
        it { is_expected.to eq(:bva_development) }
      end

      context "and it is in location 18" do
        let(:location_code) { "18" }
        it { is_expected.to eq(:bva_development) }
      end
    end

    context "when it is in history status" do
      let(:status) { "HIS" }

      context "when decided by the board" do
        let(:disposition) { "1" }
        it { is_expected.to eq(:bva_decision) }
      end

      context "when granted by the aoj" do
        let(:disposition) { "A" }
        it { is_expected.to eq(:field_grant) }
      end

      context "when withdrawn" do
        let(:disposition) { "9" }
        it { is_expected.to eq(:withdrawn) }
      end

      context "when ftr" do
        let(:disposition) { "G" }
        it { is_expected.to eq(:ftr) }
      end

      context "when ramp" do
        let(:disposition) { "P" }
        it { is_expected.to eq(:ramp) }
      end

      context "when statutory opt-in" do
        let(:disposition) { "O" }
        it { is_expected.to eq(:statutory_opt_in) }
      end

      context "when death" do
        let(:disposition) { "8" }
        it { is_expected.to eq(:death) }
      end

      context "when reconsideration by letter" do
        let(:disposition) { "R" }
        it { is_expected.to eq(:reconsideration) }
      end

      context "when an unmatched merge" do
        let(:disposition) { "M" }
        it { is_expected.to eq(:merged) }
      end

      context "when any other disposition" do
        let(:disposition) { "Z" }
        it { is_expected.to eq(:other_close) }
      end
    end

    context "when it is in remand status" do
      let(:status) { "REM" }
      let(:decision_date) { 3.days.ago }
      it { is_expected.to eq(:remand) }

      context "and it has received a post-decision ssoc" do
        let(:ssoc_date1) { 1.day.ago }
        it { is_expected.to eq(:remand_ssoc) }
      end

      context "and it has a pre-decision ssoc" do
        let(:ssoc_date1) { 5.days.ago }
        it { is_expected.to eq(:remand) }
      end
    end

    context "when it is in motion status" do
      let(:status) { "MOT" }
      it { is_expected.to eq(:motion) }
    end

    context "when it is in cavc status" do
      let(:status) { "CAV" }
      it { is_expected.to eq(:cavc) }
    end
  end

  context "#alerts" do
    subject { series.alerts }
    let(:form9_date) { nil }

    it "returns list of alerts" do
      expect(!subject.empty?).to be_truthy
      expect(subject.first[:type]).to eq(:form9_needed)
    end
  end

  context "#docket" do
    subject { series.docket }

    before { DocketSnapshot.create }

    context "when the appeal is original and not aod" do
      before { series.appeals.each { |appeal| appeal.aod = false } }

      it "has a docket" do
        expect(subject).to_not be_nil
      end
    end

    context "when the appeal is post-cavc" do
      before { series.appeals.each { |appeal| appeal.aod = false } }
      let(:type) { "7" }

      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end

    context "when the appeal is aod" do
      let(:latest_case) do
        create(:case, :aod)
      end

      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end

    context "when there is no form 9" do
      before { series.appeals.each { |appeal| appeal.aod = false } }
      let(:form9_date) { nil }

      it "does not have a docket" do
        expect(subject).to be_nil
      end
    end
  end

  context "#docket_hash" do
    subject { series.docket_hash }

    context "when the case is aod" do
      let(:latest_case) do
        create(:case, :aod)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  context "#description" do
    subject { series.description }

    context "when there is a single issue" do
      let(:latest_appeal_issues) { [create(:case_issue, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")] }

      it { is_expected.to eq("Service connection, limitation of thigh motion (flexion)") }
    end

    context "when that issue is new and materials" do
      let(:latest_appeal_issues) { [create(:case_issue, issprog: "02", isscode: "15", isslev1: "04", isslev2: "5252")] }

      it { is_expected.to eq("Service connection, limitation of thigh motion (flexion)") }
    end

    context "when there are multiple issues" do
      let(:latest_appeal_issues) do
        [
          create(:case_issue, issseq: 1, issprog: "02", isscode: "17", isslev1: "02"),
          create(:case_issue, issseq: 2, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252"),
          create(:case_issue, issseq: 3, issprog: "02", isscode: "12", isslev1: "05"),
          create(:case_issue, issseq: 4, issprog: "02", isscode: "15", isslev1: "03", isslev2: "9432")
        ]
      end

      it { is_expected.to eq("Service connection, limitation of thigh motion (flexion), and 3 others") }
    end

    context "when those issues do not have commas" do
      let(:latest_appeal_issues) do
        [
          create(:case_issue, issseq: 1, issprog: "02", isscode: "17", isslev1: "02"),
          create(:case_issue, issseq: 2, issprog: "02", isscode: "12", isslev1: "05")
        ]
      end

      it { is_expected.to eq("100% rating for individual unemployability and 1 other") }
    end
  end
end
