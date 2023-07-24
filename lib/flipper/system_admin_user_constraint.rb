# frozen_string_literal: true

module Flipper
  class SystemAdminUserConstraint
    # A basic user functions check to see if a user should be permitted access to flipper
    #
    # To grant the "System Admin" function to a user run the following:
    # Functions.grant!("System Admin", users: "YOUR_CSS_ID")
    def matches?(request)
      return true if Rails.env.development?

      User.from_session(request.session)&.admin?
    end
  end
end
