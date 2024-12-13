# frozen_string_literal: true

describe "brieffs_awaiting_hearing_scheduling" do
  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM brieffs_awaiting_hearing_scheduling()"
    )
  end

  context "with legacy appeals meeting the criteria" do
    include_context "Legacy appeals that may or may not appear in the NHQ"

    after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

    it "the expected brieff records are returned", bypass_cleaner: true do
      expect(subject.to_a.pluck("bfkey")).to match_array(desired_vacols_ids)
    end

    it "the return type has all of the same columns as the source table", bypass_cleaner: true do
      expect(VACOLS::Case.columns.map(&:name)).to match_array(subject.fields)
    end
  end

  context "with no legacy appeals meeting the criteria" do
    it "the function doesn't throw an error" do
      expect { subject }.to_not raise_exception
    end
  end
end
