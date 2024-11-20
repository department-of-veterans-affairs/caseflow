# frozen_string_literal: true

describe "issues_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM issues_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals' ISSUES meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    let!(:issues) do
      legacy_appeals_with_active_sched_task.map do
        create(:case_issue, isskey: _1.case_record.bfkey)
      end + Array.new(2).map do
        # Places two issues onto this single appeal
        create(:case_issue, isskey: legacy_appeal_with_two_active_sched_tasks.case_record.bfkey)
      end
    end

    it "the expected ISSUES records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("isskey").uniq).to match_array(desired_vacols_ids)
    end

    it "cases with multiple issues have all issues appear in the result set", bypass_cleaner: true do
      expect(
        subject.to_a.pluck("isskey").filter { _1 == legacy_appeal_with_two_active_sched_tasks.vacols_id }.size
      ).to eq 2
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::CaseIssue.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals' ISSUES meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
