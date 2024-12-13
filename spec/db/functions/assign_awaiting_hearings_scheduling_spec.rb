# frozen_string_literal: true

describe "assign_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM assign_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals' ASSIGN meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    let!(:diary_entries) do
      legacy_appeals_with_active_sched_task.map do
        create(:diary, tsktknm: _1.vacols_id)
      end + Array.new(2).map do
        # Places two issues onto this single appeal
        create(:diary, tsktknm: legacy_appeal_with_two_active_sched_tasks.vacols_id)
      end
    end

    it "the expected ASSIGN records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("tsktknm").uniq).to match_array(desired_vacols_ids)
    end

    it "cases with multiple diary entries have them all appear in the result set", bypass_cleaner: true do
      expect(
        subject.to_a.pluck("tsktknm").filter { _1 == legacy_appeal_with_two_active_sched_tasks.vacols_id }.size
      ).to eq 2
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::Diary.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals' ASSIGN meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
