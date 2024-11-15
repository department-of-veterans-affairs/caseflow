# frozen_string_literal: true

describe CheckVeteranResidenceLocationJob, :all_dbs do
  include ActiveJob::TestHelper

  let!(:fl_vet_attrs) { { file_number: "1238", ssn: "1111111111", state: "FL", country: "US" } }
  let!(:fl_vet_outdated_attrs) do
    { file_number: "1239", ssn: "1111111112", state: "FL", country: "US" }
  end
  let!(:az_vet_recently_processed_attrs) do
    { file_number: "1237", ssn: "1111111115", state: "AZ", country: "US" }
  end
  let!(:ca_vet_outdated_attrs) do
    { file_number: "1235", ssn: "1111111113", state: "CA", country: "US" }
  end
  let!(:international_vet_attrs) { { file_number: "1240", ssn: "1111111116", state: nil, country: "PI" } }

  before do
    Generators::Veteran.build(fl_vet_attrs).update!(
      state_of_residence: nil,
      country_of_residence: nil,
      residence_location_last_checked_at: nil
    )
    Generators::Veteran.build(az_vet_recently_processed_attrs).update!(
      state_of_residence: "AZ",
      country_of_residence: "USA",
      residence_location_last_checked_at: 1.day.ago
    )
    Generators::Veteran.build(ca_vet_outdated_attrs).update!(
      state_of_residence: nil,
      country_of_residence: nil,
      residence_location_last_checked_at: 2.weeks.ago
    )
    Generators::Veteran.build(fl_vet_outdated_attrs).update!(
      state_of_residence: "FL",
      country_of_residence: "USA",
      residence_location_last_checked_at: 2.weeks.ago
    )
    Generators::Veteran.build(international_vet_attrs).update!(
      state_of_residence: nil,
      country_of_residence: nil,
      residence_location_last_checked_at: nil
    )
  end

  describe "#perform" do
    it "updates the veteran residence location", bypass_cleaner: true do
      vet_before_job_run = Veteran.find_by_file_number_or_ssn("1238")
      expect(vet_before_job_run.address.state).to eq("FL")

      CheckVeteranResidenceLocationJob.perform_now

      vet_after_job_run = Veteran.find_by_file_number_or_ssn("1238")
      vet2_after_job_run = Veteran.find_by_file_number("1239")

      expect(vet_after_job_run.state_of_residence).to eq "FL"
      expect(vet_after_job_run.country_of_residence).to eq "US"
      expect(vet_after_job_run.residence_location_last_checked_at).to be_within(5.minutes).of(Time.zone.now)
      expect(vet2_after_job_run.residence_location_last_checked_at).to be_within(5.minutes).of(Time.zone.now)
    end

    it "catches standard errors within the parallel threads", bypass_cleaner: true do
      allow_any_instance_of(Veteran).to receive(:address).and_raise(BGS::ShareError, "Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error).at_least(4).times

      perform_enqueued_jobs { CheckVeteranResidenceLocationJob.perform_later }
    end

    # Clean up parallel threads
    after(:each) { clean_up_after_threads }

    def clean_up_after_threads
      DatabaseCleaner.clean_with(:truncation, except: %w[vftypes issref notification_events])
    end
  end

  describe "#retrieve_veterans" do
    it "retrieves all veterans matching the criteria" do
      res = CheckVeteranResidenceLocationJob.new

      expect(res.send(:retrieve_veterans).length).to be(4)
    end

    it "raises errors for connection issues" do
      allow(Veteran).to receive(:where).and_raise(StandardError, "Connection Error")

      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error)

      res = CheckVeteranResidenceLocationJob.new
      expect { res.send(:retrieve_veterans) }.to raise_error
    end
  end

  describe "#batch_update_veterans" do
    it "retrieves all veterans matching the criteria" do
      res = CheckVeteranResidenceLocationJob.new

      vet = Veteran.find_by_file_number_or_ssn("1235")
      vet_updates = [{ id: vet.id, state_of_residence: "CA", country_of_residence: "US",
                       residence_location_last_checked_at: Time.zone.now }]

      res.send(:batch_update_veterans, vet_updates)

      vet_after_update = Veteran.find_by_file_number_or_ssn("1235")

      expect(vet_after_update.state_of_residence).to eq "CA"
      expect(vet_after_update.country_of_residence).to eq "US"
      expect(vet_after_update.residence_location_last_checked_at).to be_within(5.minutes).of(Time.zone.now)
    end

    it "raises errors for connection issues" do
      expect_any_instance_of(CheckVeteranResidenceLocationJob).to receive(:log_error)

      res = CheckVeteranResidenceLocationJob.new
      expect { res.send(:batch_update_veterans, {}) }.to raise_error
    end
  end
end
