# frozen_string_literal: true

describe PromulgatedRating do
  context ".from_bgs_hash" do
    subject { PromulgatedRating.from_bgs_hash(bgs_record) }

    let(:bgs_record) do
      {
        comp_id: {
          prfil_dt: Time.zone.today - 5.days,
          ptcpnt_vet_id: "ZAZA"
        },
        prmlgn_dt: Time.zone.today - 4.days
      }
    end

    it { is_expected.to be_a(Rating) }

    it do
      is_expected.to have_attributes(
        participant_id: "ZAZA",
        profile_date: Time.zone.today - 5.days,
        promulgation_date: Time.zone.today - 4.days
      )
    end
  end
end
