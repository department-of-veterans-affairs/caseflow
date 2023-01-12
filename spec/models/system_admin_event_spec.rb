# frozen_string_literal: true

describe SystemAdminEvent do
  let(:valid_user) { create(:user) }
  let(:invalid_event_type) { "invalid_event_type" }
  let(:veteran_extract) { "veteran_extract" }
  let(:ran_scheduled_job) { "ran_scheduled_job" }

  describe "validation" do
    it "fails with no user or event_type" do
      event = SystemAdminEvent.new

      expect(event.valid?).to eq(false)
      expect(event.errors.details).to have_key(:user)
      expect(event.errors.details).to have_key(:event_type)
    end

    it "fails with a user but no event_type" do
      event = SystemAdminEvent.new(user: valid_user)

      expect(event.valid?).to eq(false)
      expect(event.errors.details).not_to have_key(:user)
      expect(event.errors.details).to have_key(:event_type)
    end

    it "fails with a user and invalid event type" do
      expect { SystemAdminEvent.new(user: valid_user, event_type: invalid_event_type) }
        .to raise_error(ArgumentError)
    end

    it "succeeds with a user and each valid event type" do
      event1 = SystemAdminEvent.new(user: valid_user, event_type: veteran_extract)
      event2 = SystemAdminEvent.new(user: valid_user, event_type: ran_scheduled_job)

      expect(event1.valid?).to eq(true)
      expect(event2.valid?).to eq(true)
    end
  end
end
