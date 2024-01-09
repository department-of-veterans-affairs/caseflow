# frozen_string_literal: true

describe ConferenceLink do
  let(:hearing_day) { create(:hearing_day) }
  let(:created_by_user) { create(:user) }

  it "Base ConferenceLink class records cannot be created directly" do
    expect { ConferenceLink.create!(hearing_day: hearing_day, created_by: created_by_user) }.to raise_error(
      NotImplementedError
    )
  end
end
