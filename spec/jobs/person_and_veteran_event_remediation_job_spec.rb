# frozen_string_literal: true

require "support/shared_context/sync_vet_remediations"

RSpec.describe PersonAndVeteranEventRemediationJob do
  include ActiveJob::TestHelper

  include_context "sync_vet_remediations"

  context ".perform" do
    let(:current_user) { create(:user, roles: ["System Admin"]) }
    let(:create_job) do
      PersonAndVeteranEventRemediationJob.new
    end
    let(:person_event_record) {
      create(:person_event_record, info: { "before_data" =>
      {
        "id" => 5854,
        "participant_id" => "601486438",
        "date_of_birth" => "Thu, 01 Jan 1970",
        "created_at" => "Wed, 30 Oct 2024 17:32:46.642838000 UTC +00:00",
        "updated_at" => "Wed, 30 Oct 2024 17:32:47.112988000 UTC +00:00",
        "first_name" => "HEIDI",
        "last_name" => "HERMAN",
        "middle_name" => nil,
        "name_suffix" => nil,
        "email_address" => nil,
        "ssn" => "683378050"
      }, "record_data" => {
        "id" => 5854,
        "participant_id" => "601486438",
        "date_of_birth" => "Thu, 01 Jan 1970",
        "created_at" => "Wed, 30 Oct 2024 17:32:46.642838000 UTC +00:00",
        "updated_at" => "Wed, 30 Oct 2024 17:32:47.112988000 UTC +00:00",
        "first_name" => "HEIDI",
        "last_name" => "HERMAN",
        "middle_name" => nil,
        "name_suffix" => nil,
        "email_address" => nil,
        "ssn" => "683378050"
      }, "update_type" => "U" })
    }

    let(:person_1) { create(:person, participant_id: "601486438", ssn: "683378050") }
    let(:person_2) { create(:person, participant_id: "601486439", ssn: "683378050") }

    subject { create_job }
    # we are uncertain how to get staged data for an event to test these.
    # would we need/want to create a factory or just mock up an Event hash?

    it "sets a current user" do
      expect(current_user).to be_an_instance_of(User)
    end

    xit "finds and remediates duplicate person records" do
      subject.perform_now
      expect(person_2).to be_deleted
    end

    xit "sends an array of found veteran ids with changed file numbers" do
      # get some sort of count of veteran ids with changed file numbers that get returned
    end

    xit "sends an array of found person ids with same ssn numbers" do
      # get some sort of count of dup person ids that get returned
    end

    xit "sends an array of found veteran ids with changed file numbers" do
      # get some sort of count of veteran ids with changed file numbers that get returned
    end
  end
end
