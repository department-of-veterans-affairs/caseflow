# frozen_string_literal: true

RSpec.describe PersonAndVeteranEventRemediationJob do
  include ActiveJob::TestHelper

  # we are uncertain how to get staged data for an event to test these.
  # would we need/want to create a factory or just mock up an Event hash like below.

  describe ".set_up" do
    # subject { described_class.new.perform(appeal_id: appeal.id, appeal_type: appeal.class.name) }
    let(:current_user) { create(:user, roles: ["System Admin"]) }

    it "sets a current user" do
      expect(current_user).to be_an_instance_of(User)
    end
  end

  # event_record = {
  #   info => {
  #     before_data => {
  #       # vet attributes before event
  #     },
  #     record_data =>{
  #       # vet info upon event creation
  #     }
  #   }
  # }

  describe ".perform" do
    xit "sends an array of found dup person evented records to service class" do
      # get some sort of count of dup person ids that get returned
    end

    xit "sends an array of found veteran ids with changed file numbers" do
      # get some sort of count of veteran ids with changed file numbers that get returned
    end
  end

  describe ".find and remediate duplicate people" do
    xit "sends an array of found person ids with same ssn numbers" do
      # get some sort of count of dup person ids that get returned
    end
  end

  describe ".find and update veteran records" do
    xit "sends an array of found veteran ids with changed file numbers" do
      # get some sort of count of veteran ids with changed file numbers that get returned
    end
  end
end
