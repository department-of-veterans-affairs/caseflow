# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create a new User
# when an Event is received and that specific User does not already exist in Caseflow
class Events::CreateUserOnEvent
  class << self
    def handle_user_creation_on_event(event:, css_id:, station_id:)
      unless user_exist?(css_id)
        create_inactive_user(event, css_id, station_id)
      end
    end

    def user_exist?(css_id)
      User.where(css_id: css_id).exists?
    end

    def create_inactive_user(event, css_id, station_id)
      user = User.create!(css_id: css_id.upcase, station_id: station_id, status: Constants.USER_STATUSES.inactive)
      # create Event record indicating this is a backfilled User
      EventRecord.create!(event: event, evented_record: user)
      user
    end
  end
end
