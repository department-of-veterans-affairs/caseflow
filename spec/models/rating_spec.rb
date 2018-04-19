require "rails_helper"

describe Rating do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".fetch_timely" do
    subject { Rating.fetch_timely(participant_id: "DRAYMOND") }

    # TODO: Shane- why are we setting a promulgation_date here? does it matter?
    let!(:rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: Time.zone.today - 371.days,
        profile_date: Time.zone.today - 371.days
      )
    end

    let!(:untimely_rating) do
      Generators::Rating.build(
        participant_id: "DRAYMOND",
        promulgation_date: Time.zone.today - 3720.days,
        profile_date: Time.zone.today - 3720.days
      )
    end

    # TODO: How can we simulate "broken" date filtering in BGSService?
    # let!(:untimely_rating_in_service_range) do
    #   Generators::Rating.build(
    #     promulgation_date: 
    #     profile_date:
    #   )
    # end

    it "returns rating objects for all timely ratings" do
      expect(subject.count).to eq(1)
      expect(subject[0][:comp_id][:ptcpnt_vet_id]).to eq("DRAYMOND")
    end

    context "when multiple timely ratings exist" do
      # TODO: need to delete old ratings between tests 
      let!(:another_rating) do
        Generators::Rating.build(
          participant_id: "DRAYMOND",
          promulgation_date: Time.zone.today - 300.days,
          profile_date: Time.zone.today - 300.days
        )
      end
     
      it "returns rating objects for all timely ratings" do
        expect(subject.count).to eq(2)
        expect(subject[0][:comp_id][:ptcpnt_vet_id]).to eq("DRAYMOND")
      end
  end
end
