# frozen_string_literal: true

describe "hearsched_related_to_cases_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM hearsched_related_to_cases_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals' HEARSCHED meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    let!(:hearsched_records) do
      legacy_appeals_with_active_sched_task.first(3).map do |legacy_appeal|
        create(:case_hearing, folder_nr: legacy_appeal.vacols_id)
      end
    end

    let(:vacols_ids_of_cases_with_hearings) { legacy_appeals_with_active_sched_task.first(3).pluck(:vacols_id) }

    it "the expected HEARSCHED records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("folder_nr").uniq).to match_array(vacols_ids_of_cases_with_hearings)
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::CaseHearing.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals' HEARSCHED meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
