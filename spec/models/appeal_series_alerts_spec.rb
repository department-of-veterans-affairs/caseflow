# frozen_string_literal: true

describe AppealSeriesAlerts, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    allow(AppealRepository).to receive(:latest_docket_month) { docket_month }
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
    DocketSnapshot.create
  end

  let(:docket_month) { 1.year.ago.to_date.beginning_of_month }

  let(:appeal) do
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :type_original,
        :certified,
        bfcorlid: "999887777S",
        bfcurloc: location_code,
        bfdrodec: 1.year.ago,
        bfdsoc: soc_date,
        bfd19: form9_date,
        certification_date: certification_date,
        bfddec: decision_date,
        bfdc: disposition,
        bfmpro: status,
        bfregoff: "RO13",
        case_hearings: hearings,
        bfso: "F",
        case_issues: [create(:case_issue, :compensation)]
      ))
  end

  let(:series) { AppealSeries.create(appeals: [appeal]) }
  let(:hearings) { [] }
  let(:status) { "ADV" }
  let(:location_code) { "77" }
  let(:soc_date) { 5.days.ago }
  let(:form9_date) { nil }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }

  let(:alerts) { AppealSeriesAlerts.new(appeal_series: series).all }

  context "#all" do
    context "form9_needed alert" do
      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :form9_needed }
        expect(alert).to_not be_nil
        expect(alert[:details][:due_date]).to eq(55.days.from_now.to_date)
      end
    end

    context "scheduled_hearing alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let(:hearing_day) do
        create(:case_hearing,
               hearing_type: HearingDay::REQUEST_TYPES[:video],
               hearing_date: 1.day.from_now,
               folder_nr: "VIDEO RO13")
      end
      let(:hearings) do
        [build(:case_hearing, hearing_date: hearing_day.hearing_date, vdkey: hearing_day.id)]
      end

      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :scheduled_hearing }
        expect(alert).to_not be_nil
        expect(alert[:details][:date]).to eq(1.day.from_now.to_date)
        expect(alert[:details][:type]).to eq("video")
        expect(alert[:details][:location]).to eq("Baltimore regional office")
      end
    end

    context "hearing_no_show alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let(:hearings) do
        [build(:case_hearing, :disposition_no_show, hearing_date: hearing_date)]
      end
      let(:hearing_date) { 1.day.ago }

      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :hearing_no_show }
        expect(alert).to_not be_nil
        expect(alert[:details][:date]).to eq(1.day.ago.to_date)
        expect(alert[:details][:due_date]).to eq(14.days.from_now.to_date)
      end

      context "when more than 15 days ago" do
        let(:hearing_date) { 16.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :hearing_no_show }).to be_nil
        end
      end
    end

    context "held_for_evidence alert" do
      # Save appeal so hearings can be associated to it
      before { appeal.save! }
      let(:certification_date) { 3.days.ago }
      let(:hearings) do
        [build(:case_hearing, :disposition_held, hearing_date: hearing_date, holddays: 30)]
      end
      let(:hearing_date) { 1.day.ago }

      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :held_for_evidence }
        expect(alert).to_not be_nil
        expect(alert[:details][:due_date]).to eq(29.days.from_now.to_date)
      end

      context "when older than the hold_open time" do
        let(:hearing_date) { 31.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :held_for_evidence }).to be_nil
        end
      end
    end

    context "decision_soon alert" do
      let(:form9_date) { 1.year.ago }
      let(:status) { "ACT" }

      before do
        series.appeals.each do |appeal|
          appeal.aod = false
          appeal.case_assignment_exists = true
        end
      end

      it "includes an alert" do
        expect(alerts.find { |a| a[:type] == :decision_soon }).to_not be_nil
      end
    end

    context "blocked_by_vso alert" do
      let(:form9_date) { docket_month }
      let(:status) { "ACT" }
      let(:location_code) { "55" }

      before { series.appeals.each { |appeal| appeal.aod = false } }

      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :blocked_by_vso }
        expect(alert).to_not be_nil
        expect(alert[:details][:vso_name]).to eq("Military Order of the Purple Heart")
      end
    end

    context "cavc_option alert" do
      let(:status) { "HIS" }
      let(:decision_date) { 1.day.ago }
      let(:disposition) { "1" }

      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :cavc_option }
        expect(alert).to_not be_nil
        expect(alert[:details][:due_date]).to eq(119.days.from_now.to_date)
      end

      context "when older than 120 days" do
        let(:decision_date) { 121.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :cavc_option }).to be_nil
        end
      end

      context "when not a Board decision" do
        let(:disposition) { "B" }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :cavc_option }).to be_nil
        end
      end
    end

    context "ramp alert" do
      let!(:ramp_election) { RampElection.create(veteran_file_number: "999887777", notice_date: notice_date) }
      let(:notice_date) { 30.days.ago }

      context "when notice date is within the last 60 days" do
        it "includes an alert" do
          alert = alerts.find { |a| a[:type] == :ramp_eligible }
          expect(alert).to_not be_nil
          expect(alert[:details][:date]).to eq(30.days.ago.to_date)
          expect(alert[:details][:due_date]).to eq(30.days.from_now.to_date)
        end
      end

      context "when no longer eligible" do
        let(:status) { "HIS" }

        it "includes an ineligible alert" do
          alert = alerts.find { |a| a[:type] == :ramp_ineligible }
          expect(alert).to_not be_nil
          expect(alert[:details][:date]).to eq(30.days.ago.to_date)
        end
      end

      context "when not a Board decision" do
        let(:notice_date) { 61.days.ago }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :ramp_eligible }).to be_nil
          expect(alerts.find { |a| a[:type] == :ramp_ineligible }).to be_nil
        end
      end

      context "when a Veteran has opted into RAMP without receiving a letter" do
        let(:notice_date) { nil }

        it "does not include an alert" do
          expect(alerts.find { |a| a[:type] == :ramp_eligible }).to be_nil
          expect(alerts.find { |a| a[:type] == :ramp_ineligible }).to be_nil
        end
      end
    end

    context "ama_opt_in_eligible alert" do
      it "includes an alert" do
        alert = alerts.find { |a| a[:type] == :ama_opt_in_eligible }
        expect(alert).to_not be_nil
        expect(alert[:details][:due_date]).to eq(55.days.from_now.to_date)
      end
    end
  end
end
