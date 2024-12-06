# frozen_string_literal: true

describe "gather_bfcorkeys_of_hearing_schedulable_legacy_cases" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM gather_bfcorkeys_of_hearing_schedulable_legacy_cases()"
    ).first["gather_bfcorkeys_of_hearing_schedulable_legacy_cases"]
  end

  context "with legacy cases meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    let(:desired_bfcorkeys) do
      legacy_appeals = legacy_appeals_with_active_sched_task + [legacy_appeal_with_two_active_sched_tasks]

      legacy_appeals.map(&:case_record).pluck(:bfcorkey)
    end

    after(:each) { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    it "only the desired appeals' IDs are returned and are formatted properly", bypass_cleaner: true do
      expect(subject.scan(/'\d*'/).size).to eq desired_bfcorkeys.size

      expect(subject.delete("'").split(",")).to match_array(desired_bfcorkeys)
    end
  end

  context "with no legacy appeals meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
