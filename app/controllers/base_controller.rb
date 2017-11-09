class BaseController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  after_action :track_request_id

  def track_request_id
    ::NewRelic::Agent.add_custom_attributes(request_id: request.uuid)
  end
end
