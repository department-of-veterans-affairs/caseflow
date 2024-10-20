# frozen_string_literal: true

describe ConferenceLink do
  let(:hearing_day) { create(:hearing_day) }
  let(:created_by_user) { create(:user) }
  let(:hearing) { create(:hearing) }

  it "Base ConferenceLink class records cannot be created directly" do
    expect { ConferenceLink.create!(hearing_day: hearing_day, created_by: created_by_user) }.to raise_error(
      NotImplementedError
    )
  end

  it "can belong to a hearing day" do
    conference_link = ConferenceLink.new(hearing_day_id: hearing_day.id)
    expect(conference_link.hearing_day).to match(hearing_day)
  end

  it "can belong to a hearing" do
    conference_link = ConferenceLink.new(hearing_id: hearing.id, hearing_type: "Hearing")
    expect(conference_link.hearing).to match(hearing)
  end
end
