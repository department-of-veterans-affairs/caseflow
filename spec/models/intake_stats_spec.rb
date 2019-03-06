# frozen_string_literal: true

require "rails_helper"

describe IntakeStats do
  before do
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))
    Rails.cache.clear
  end

  context ".throttled_calculate_all!" do
    subject { IntakeStats.throttled_calculate_all! }
    context "when not previously calculated" do
      it "calculates stats" do
        expect(IntakeStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("IntakeStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated more than 20 minutes ago" do
      before { Rails.cache.write("IntakeStats-last-calculated-timestamp", 21.minutes.ago.to_i) }

      it "calculates stats" do
        expect(IntakeStats).to receive(:calculate_all!)
        subject
        expect(Rails.cache.read("IntakeStats-last-calculated-timestamp")).to eq(Time.now.to_i)
      end
    end

    context "when last calculated less than 20 minutes ago" do
      before { Rails.cache.write("IntakeStats-last-calculated-timestamp", 19.minutes.ago.to_i) }

      it "doesn't recalculate stats" do
        expect(IntakeStats).to_not receive(:calculate_all!)
        subject
      end
    end
  end

  context ".intake_series_statuses" do
    subject { IntakeStats.intake_series_statuses(4.days.ago...Time.zone.now) }

    let(:user) { Generators::User.build }

    let!(:out_of_range_series) do
      RampElectionIntake.create!(
        veteran_file_number: "0000",
        completed_at: 5.days.ago,
        completion_status: :success,
        user: user
      )
    end

    let!(:successful_series) do
      [
        RampElectionIntake.create!(
          veteran_file_number: "1111",
          completed_at: 3.hours.ago,
          completion_status: :success,
          user: user
        ),
        RampElectionIntake.create!(
          veteran_file_number: "1111",
          completed_at: 2.hours.ago,
          completion_status: :success,
          user: user
        )
      ]
    end

    let!(:error_series) do
      [
        RampElectionIntake.create!(
          veteran_file_number: "2222",
          completed_at: 5.hours.ago,
          completion_status: :error,
          error_code: :no_active_appeals,
          user: user
        ),
        RampElectionIntake.create!(
          veteran_file_number: "2222",
          completed_at: 6.hours.ago,
          completion_status: :error,
          error_code: :no_eligible_appeals,
          user: user
        ),
        RampElectionIntake.create!(
          veteran_file_number: "2222",
          completed_at: 4.hours.ago,
          completion_status: :success,
          error_code: :did_not_receive_ramp_election,
          user: user
        )
      ]
    end

    context "sumarizes status for series of intakes for the same veteran in the range" do
      it { is_expected.to eq(%w[no_active_appeals success]) }
    end
  end
end
