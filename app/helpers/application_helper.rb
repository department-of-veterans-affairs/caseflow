# frozen_string_literal: true

module ApplicationHelper
  def current_ga_path
    full_path = request.env["PATH_INFO"]
    route = Rails.application.routes.recognize_path(full_path, method: request.env["REQUEST_METHOD"])
    return full_path unless route

    ["", route[:controller], route[:action]].join("/")
  end

  def handle_non_critical_error(endpoint, error)
    error_type = error.class.name
    if !error.class.method_defined? :serialize_response
      code = (error.class == ActiveRecord::RecordNotFound) ? 404 : 500
      error = Caseflow::Error::SerializableError.new(code: code, message: error.to_s)
    end

    DataDogService.increment_counter(
      metric_group: "errors",
      metric_name: "non_critical",
      app_name: RequestStore[:application],
      attrs: {
        endpoint: endpoint,
        error_type: error_type,
        error_code: error.code
      }
    )
    error
  end
end
