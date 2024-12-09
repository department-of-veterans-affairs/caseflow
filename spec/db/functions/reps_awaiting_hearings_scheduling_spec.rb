# frozen_string_literal: true

describe "reps_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM reps_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals' REPS meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    let!(:reps) do
      legacy_appeals_with_active_sched_task.map do
        create(:representative, repkey: _1.vacols_id)
      end + [
        create(:representative, repkey: legacy_appeal_with_two_active_sched_tasks.vacols_id)
      ]
    end

    it "the expected REPS records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("repkey").uniq).to match_array(desired_vacols_ids)
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::Representative.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals' REPS meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
