# frozen_string_literal: true

# Service Class that will be utilized by Events::DecisionReviewCreated to create a new User
# when an Event is received and that specific User does not already exist in Caseflow
class Events::CreateUserOnEvent
  class << self
    def handle_user_creation_on_event(event:, css_id:, station_id:)
      user = User.find_by(css_id: css_id)
      return user if user

      create_inactive_user(event, css_id, station_id)
    rescue StandardError => error
      raise Caseflow::Error::DecisionReviewCreatedUserError, error.message
    end

    def create_inactive_user(event, css_id, station_id)
      user = User.create!(css_id: css_id.upcase, station_id: station_id, status: Constants.USER_STATUSES.inactive)
      # create Event record indicating this is a backfilled User
      EventRecord.create!(event: event, evented_record: user)
      user
    end
  end
end
