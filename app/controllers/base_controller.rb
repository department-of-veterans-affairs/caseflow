class BaseController < ActionController::Base
  after_action :track_request_id

  def track_request_id
    ::NewRelic::Agent.add_custom_attributes(request_id: request.uuid)
  end
end
