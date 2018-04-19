require "rails_helper"

describe Rating do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".fetch_timely" do
    subject { Rating.fetch_timely(participant_id: "DRAYMOND") }

    let!(:rating) do
      Generators::Rating.build(
        promulgation_date: Time.zone.today - 372,
        profile_date: Time.zone.today - 372
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        promulgation_date: 
        profile_date:
      )
    end

    let!(:untimely_rating_in_service_range) do
      Generators::Rating.build(
        promulgation_date: 
        profile_date:
      )
    end

    it "returns rating objects for all timely ratings" do
    end
  end
end
