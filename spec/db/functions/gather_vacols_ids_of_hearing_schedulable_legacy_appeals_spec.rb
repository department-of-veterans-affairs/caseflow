# frozen_string_literal: true

describe "gather_vacols_ids_of_hearing_schedulable_legacy_appeals" do
  include_context "Legacy appeals that may or may not appear in the NHQ"

  subject do
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM gather_vacols_ids_of_hearing_schedulable_legacy_appeals()"
    ).first["gather_vacols_ids_of_hearing_schedulable_legacy_appeals"]
  end

  it "only the desired appeals' IDs are returned" do
    # Validate proper formatting
    expect(subject.scan(/'\d*'/).size).to eq desired_vacols_ids.size

    expect(subject.delete("'").split(",")).to match_array(desired_vacols_ids)
  end
end
