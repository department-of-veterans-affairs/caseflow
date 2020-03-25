# frozen_string_literal: true

class UserAlert
  attr_accessor :type, :title, :message, :auto_clear

  TYPES = {
    success: "success",
    error: "error",
    warning: "warning",
    info: "info"
  }.freeze

  def initialize(type:, title:, message: nil, auto_clear: false)
    @type = type
    @title = title
    @message = message
    @auto_clear = auto_clear
  end

  def to_hash
    {
      type: type,
      title: title,
      message: message,
      autoClear: auto_clear
    }
  end
end
