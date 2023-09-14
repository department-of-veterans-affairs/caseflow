# frozen_string_literal: true

class ExternalApi::PexipService::Response
  attr_reader :resp, :code

  def initialize(resp)
    @resp = resp
    @code = @resp.code
  end

  def data; end

  def error
    check_for_error
  end

  def success?
    !resp.error?
  end

  private

  def check_for_error
    return if success?

    # What error codes can we get?
    msg = error_message

    case code
    in (400..499) then "400"
    in (500..599) then "500"
    else
      "Something else"
    end
  end

  def error_message
    return "No error message from Webex" if resp.raw_body.empty?

    "TODO: I need to figure out how Webex IC will present its errors to us"
  end
end
