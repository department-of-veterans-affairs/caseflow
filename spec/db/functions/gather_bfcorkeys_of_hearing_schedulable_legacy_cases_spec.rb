# frozen_string_literal: true

describe "gather_bfcorkeys_of_hearing_schedulable_legacy_cases" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM gather_bfcorkeys_of_hearing_schedulable_legacy_cases()"
    ).first["gather_bfcorkeys_of_hearing_schedulable_legacy_cases"]
  end

  context "with legacy cases meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    let!(:desired_bfcorkeys) do
      cases = legacy_appeals_with_active_sched_task + [legacy_appeal_with_two_active_sched_tasks]
      bfcorkeys = cases.pluck(:bfcorkey)

      bfcorkeys.map do |bfcorkey|
        byebug
        VACOLS::Correspondent.create!(stafkey: bfcorkey)
      end

      bfcorkeys
    end

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    it "test" do
      byebug

      expect(true).to eq true
    end
  end

  context "with no legacy apepals meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
