# frozen_string_literal: true

describe "corres_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM corres_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals' correspondents meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    let(:desired_corres_ids) do
      legacy_appeals_with_active_sched_task.map { _1.case_record }.pluck(:bfcorkey) + [
        legacy_appeal_with_two_active_sched_tasks.case_record.bfcorkey
      ]
    end

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    it "the expected corres records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("stafkey")).to match_array(desired_corres_ids)
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::Correspondent.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals' correspondents meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
