# frozen_string_literal: true

module Errors
  extend ActiveSupport::Concern
  def invalid_role_error
    {
      "errors": [
        "title": "Role is Invalid",
        "detail": "User is not allowed to perform this action"
      ],
      "status": "bad_request"
    }
  end
end
