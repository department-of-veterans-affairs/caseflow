# frozen_string_literal: true

describe Events::CreateUserOnEvent do
  let!(:css_id) { "NEWUSER" }
  let!(:old_user) { create(:user, css_id: "OLDUSER") }
  let!(:station_id) { "101" }
  let!(:event) { DecisionReviewCreatedEvent.create!(reference_id: "1") }

  describe "#user_exist?" do
    subject { described_class }

    context "When there is no previous User" do
      it "should return false" do
        expect(subject.user_exist?(css_id)).to be_falsey
      end
    end

    context "When a User already exists" do
      it "should return true" do
        expect(subject.user_exist?(old_user.css_id)).to be_truthy
      end
    end
  end

  describe "#handle_user_creation_on_event" do
    subject { described_class.handle_user_creation_on_event(event, css_id, station_id) }

    context "When an Event is received and no User exists" do
      it "should create an Inactive User and Event Record" do
        subject
        user2 = User.find_by_css_id(css_id)
        user_event_record = EventRecord.find_by(event_id: event.id)
        expect(User.count).to eq(2)
        expect(user2.status).to eq(Constants.USER_STATUSES.inactive)
        expect(user2.event_record).to eq(user_event_record)
        expect(EventRecord.count).to eq(1)
        expect(EventRecord.first).to eq(user_event_record)
        expect(user_event_record.backfill_record).to eq(user2)
      end
    end
  end
end
