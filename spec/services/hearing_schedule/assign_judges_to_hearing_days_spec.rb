# frozen_string_literal: true

describe HearingSchedule::AssignJudgesToHearingDays do
  let(:file_name) { "validJudgeSpreadsheet.xlsx" }

  context "#load_spreadsheet_data" do
    before do
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + file_name,
                           "spec/support/#{file_name}", :filepath)
    end

    it "extracts the expected data" do
      data = described_class.load_spreadsheet_data(file_name)

      expect(data.judge_assignments.length).to eq 2
      expect(data.judge_assignments.pluck(:name).uniq).to eq ["Huels, Stuart"]
      expect(data.judge_assignments.pluck(:judge_css_id).uniq).to eq ["BVAHUELS"]
      expect(data.judge_assignments.pluck(:hearing_day_id).uniq).to eq [1, 2]
    end
  end

  context "with hearing days" do
    let(:judge1_first_name) { "Leocadia" }
    let(:judge1_last_name) { "Jarecki" }
    let(:judge1_css_id) { "BSVAJARECKI" }
    let(:judge2_first_name) { "Ayame" }
    let(:judge2_last_name) { "Jouda" }
    let(:judge2_css_id) { "BSVAJOUDA" }

    let(:judge1) do
      create(
        :user,
        :with_vacols_judge_record,
        full_name: "#{judge1_first_name} #{judge1_last_name}",
        css_id: judge1_css_id
      )
    end
    let!(:judge2) do
      create(
        :user,
        :with_vacols_judge_record,
        full_name: "#{judge2_first_name} #{judge2_last_name}",
        css_id: judge2_css_id
      )
    end
    let(:vacols_staff_one) { VACOLS::Staff.find_by(sdomainid: judge1.css_id) }
    let(:vacols_staff_two) { VACOLS::Staff.find_by(sdomainid: judge2.css_id) }

    let!(:hd1) { create(:hearing_day, judge: judge1) }
    let!(:hd2) { create(:hearing_day, judge: judge1) }

    let!(:spreadsheet_data) { double(HearingSchedule::GetSpreadsheetData) }

    let(:judge_assignment_template) do
      [:a, :b, :c].zip(HearingSchedule::ValidateJudgeSpreadsheet::SPREADSHEET_HEADERS).to_h
    end

    let(:judge_assignments) do
      [
        { name: "#{judge2_last_name}, #{judge2_first_name}", judge_css_id: judge2_css_id, hearing_day_id: hd1.id },
        { name: "#{judge2_last_name}, #{judge2_first_name}", judge_css_id: judge2_css_id, hearing_day_id: hd2.id }
      ]
    end

    before do
      allow(spreadsheet_data).to receive(:judge_assignment_template).and_return(judge_assignment_template)
      allow(spreadsheet_data).to receive(:judge_assignments).and_return(judge_assignments)
      CachedUser.sync_from_vacols
    end

    context "#stage_assignments" do
      it "stages the expected assignments" do
        hearing_days = described_class.stage_assignments(spreadsheet_data)

        expect(hearing_days.length).to eq 2
        expect(hearing_days.pluck(:judge_css_id).uniq).to eq [judge2_css_id]
      end
    end

    context "#confirm_assignments" do
      context "with good data" do
        let(:hearing_days) do
          [
            { hearing_day_id: hd1.id, judge_css_id: judge2_css_id }.with_indifferent_access,
            { hearing_day_id: hd2.id, judge_css_id: judge2_css_id }.with_indifferent_access
          ]
        end

        it "assigns the days as expected" do
          expect(hd1.judge.css_id).to eq judge1_css_id
          expect(hd2.judge.css_id).to eq judge1_css_id

          described_class.confirm_assignments(hearing_days)

          expect(hd1.reload.judge.css_id).to eq judge2_css_id
          expect(hd2.reload.judge.css_id).to eq judge2_css_id
        end
      end

      context "with bad day data" do
        let(:hearing_days) do
          [
            { hearing_day_id: 121_212, judge_css_id: judge2_css_id }.with_indifferent_access,
            { hearing_day_id: 121_212, judge_css_id: judge2_css_id }.with_indifferent_access
          ]
        end

        it "does not change day assignments" do
          expect(hd1.judge.css_id).to eq judge1_css_id
          expect(hd2.judge.css_id).to eq judge1_css_id

          described_class.confirm_assignments(hearing_days)

          expect(hd1.reload.judge.css_id).to eq judge1_css_id
          expect(hd2.reload.judge.css_id).to eq judge1_css_id
        end
      end

      context "with bad judge data" do
        let(:hearing_days) do
          [
            { hearing_day_id: hd1.id, judge_css_id: "THISISNOTAVALIDCSSID" }.with_indifferent_access,
            { hearing_day_id: hd2.id, judge_css_id: "THISISALSONOTONEOFTHOSE" }.with_indifferent_access
          ]
        end

        it "does not change day assignments" do
          expect(hd1.judge.css_id).to eq judge1_css_id
          expect(hd2.judge.css_id).to eq judge1_css_id

          described_class.confirm_assignments(hearing_days)

          expect(hd1.reload.judge.css_id).to eq judge1_css_id
          expect(hd2.reload.judge.css_id).to eq judge1_css_id
        end
      end

      context "with missing data" do
        let(:hearing_days) do
          [
            { hearing_day_id: nil, judge_css_id: judge2_css_id }.with_indifferent_access,
            { hearing_day_id: hd2.id, judge_css_id: nil }.with_indifferent_access
          ]
        end

        it "does not change day assignments" do
          expect(hd1.judge.css_id).to eq judge1_css_id
          expect(hd2.judge.css_id).to eq judge1_css_id

          described_class.confirm_assignments(hearing_days)

          expect(hd1.reload.judge.css_id).to eq judge1_css_id
          expect(hd2.reload.judge.css_id).to eq judge1_css_id
        end
      end
    end
  end
end
