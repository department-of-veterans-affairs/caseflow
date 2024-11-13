# frozen_string_literal: true

describe "brieffs_awaiting_hearing_scheduling" do
  include_context "Legacy appeals that may or may not appear in the NHQ"

  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM brieffs_awaiting_hearing_scheduling()"
    )
  end

  after { DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events]) }

  it "the expected brieff records are returned", bypass_cleaner: true do
    expect(subject.to_a.pluck("bfkey")).to match_array(desired_vacols_ids)
  end

  it "the return type has all of the same columns and analogous types as the source table", bypass_cleaner: true do
    expect(VACOLS::Case.columns.map(&:name)).to match_array(subject.fields)
  end
end
