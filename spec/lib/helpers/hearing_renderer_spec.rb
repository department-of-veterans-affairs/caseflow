# frozen_string_literal: true

require "helpers/hearing_renderer.rb"

describe "HearingRenderer" do
  let(:show_pii) { false }
  let(:renderer) { HearingRenderer.new(show_pii: show_pii) }
  let(:vacols_case) { create(:case, bfcurloc: "CASEFLOW") }
  let(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: vacols_case) }
  let(:veteran) { legacy_appeal.veteran }
  let!(:appeal) { create(:appeal, veteran: veteran, original_hearing_request_type: "central") }
  let(:judge_last_name) { "Abshire" }
  let!(:judge) do
    create(:staff, :judge_role, sdomainid: "BVAAABSHIRE", snamel: judge_last_name, snamef: "Judge")
    create(:user, css_id: "BVAAABSHIRE", full_name: "Judge #{judge_last_name}")
  end
  let(:ro) { "RO42" } # Cheyenne, WY
  let!(:hearing_day) { create(:hearing_day, request_type: "R", regional_office: ro, room: "", judge_id: judge.id) }
  let!(:hearing) { create(:hearing, appeal: appeal, hearing_day: hearing_day) }
  let!(:user) { create(:user) }

  before do
    PaperTrail.request.whodunnit = user.id
  end

  describe ".readable_date" do
    let(:include_time) { nil }
    let(:date) { Time.use_zone("UTC") { Time.zone.parse("2021-02-01 09:30") } }

    context "include time is true" do
      let(:include_time) { true }

      it "renders date with time" do
        expect(renderer.readable_date(date, include_time)).to eq "02-01-2021 9:30AM UTC"
      end
    end

    context "include time is false" do
      let(:include_time) { false }

      it "renders date without time" do
        expect(renderer.readable_date(date, include_time)).to eq "02-01-2021"
      end
    end
  end

  describe ".veteran_children" do
    it "includes all appeals associated with the veteran" do
      output = renderer.veteran_children(veteran)
      expect(output.length).to eq 2
      expect(output.first.keys.first.to_s).to include "Appeal #{appeal.id}"
      expect(output.second.keys.first.to_s).to include "LegacyAppeal #{legacy_appeal.id}"
    end
  end

  describe ".hearing_day_details" do
    it "includes expected hearing day details" do
      output = renderer.hearing_day_details(hearing_day)
      expect(output.length).to eq 1
      expect(output.first).to eq "HearingDay #{hearing_day.id} (#{ro} - Cheyenne WY, Virtual, VLJ #{judge_last_name})"
    end
  end

  describe ".hearing_day_children" do
    it "has the expected number of hearing children" do
      output = renderer.hearing_day_children(hearing_day.reload)
      expect(output.length).to eq 1
    end
  end

  describe ".appeal_type_conversions" do
    it "includes expected information about a type conversion" do
      appeal.update!(changed_hearing_request_type: "V")
      output = renderer.appeal_type_conversions(appeal)
      expect(output.length).to eq 1
      expect(output.first["to_type"]).to eq "Video"
      expect(output.first["converted_by"]).to eq user.css_id
    end
  end

  describe ".format_original_and_current_type" do
    context "no type change" do
      it "shows only the original type" do
        output = renderer.format_original_and_current_type(appeal)
        expect(output.length).to eq 1
        expect(output.first).to eq "Current type: Central"
      end
    end

    context "with type change" do
      it "shows the original and changed type" do
        appeal.update!(changed_hearing_request_type: "V")
        output = renderer.format_original_and_current_type(appeal)
        expect(output.length).to eq 1
        expect(output.first).to eq "Original Type: Central, current type: Video"
      end
    end
  end

  describe ".appeal_history" do
    context "there have been no request type changes" do
      it "describes the history" do
        output = renderer.appeal_history(appeal)
        expect(output.length).to eq 1
        expect(output.first).to eq "Current type: Central"
      end
    end

    context "there has been a request type change" do
      it "describes the history" do
        appeal.update!(changed_hearing_request_type: "V")
        output = renderer.appeal_history(appeal)
        expect(output.length).to eq 2
        expect(output.first).to eq "Original Type: Central, current type: Video"
        expect(output.second).to include "Converted to Video from Central by #{user.css_id}"
      end
    end
  end

  describe ".notes_or_include_pii_info" do
    let(:notes) { "hello world" }

    context "show_pii is false" do
      it "asks the user to pass show_pii parameter" do
        output = renderer.notes_or_include_pii_info(notes)
        expect(output).to include "'show_pii: true'"
      end
    end

    context "show_pii is true" do
      let(:show_pii) { true }

      it "shows the content of the note" do
        output = renderer.notes_or_include_pii_info(notes)
        expect(output).to eq notes
      end

      context "note contains a forward slash" do
        let(:notes) { "hello / world" }

        it "replaces it with a pipe symbol" do
          output = renderer.notes_or_include_pii_info(notes)
          expect(output).to eq "hello | world"
        end
      end

      context "note is passed in list format" do
        let(:notes) { %w[hello world] }

        it "formats the list elements into a string" do
          output = renderer.notes_or_include_pii_info(notes)
          expect(output).to eq "hello world"
        end
      end
    end
  end

  describe ".hearing_task_children" do
    let(:show_pii) { true }
    let!(:appeal) do
      create(:appeal, :with_schedule_hearing_tasks, veteran: veteran, original_hearing_request_type: "central")
    end

    it "describes the hearing note and the children of the hearing task" do
      h_task = appeal.tasks.find_by(type: HearingTask.name)
      sh_task = appeal.tasks.find_by(type: ScheduleHearingTask.name)
      h_task.update!(instructions: ["some instructions"])

      output = renderer.hearing_task_children(h_task)
      expect(output.length).to eq 2
      expect(output.first).to include "some instructions"
      expect(output.second).to include "ScheduleHearingTask #{sh_task.id}"
      expect(output.second).to include "assigned"
    end
  end
end
