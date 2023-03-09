# frozen_string_literal: true

module ApplicationHelper
  def current_ga_path
    full_path = request.env["PATH_INFO"]
    route = Rails.application.routes.recognize_path(full_path, method: request.env["REQUEST_METHOD"])
    return full_path unless route

    ["", route[:controller], route[:action]].join("/")
  end

  def flash_messages
    flash.map do |type, title, text|
      { id: text.object_id, type: type, title: title, text: text }
    end
  end
end
