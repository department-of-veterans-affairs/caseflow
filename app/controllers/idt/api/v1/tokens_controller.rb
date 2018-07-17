class Idt::Api::V1::TokensController < ActionController::Base
  protect_from_forgery with: :null_session
  include TrackRequestId

  rescue_from StandardError do |error|
    Raven.capture_exception(error)

    render json: {
      "errors": [
        "status": "500",
        "title": "Unknown error occured",
        "detail": "#{error} (Sentry event id: #{Raven.last_event_id})"
      ]
    }, status: 500
  end

  def generate_token
    key, token = Idt::Token.generate_proposed_token_and_one_time_key
    render json: { one_time_key: key, token: token }, status: 200
  end
end
