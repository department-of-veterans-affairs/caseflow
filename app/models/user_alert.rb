# frozen_string_literal: true

class UserAlert
  attr_accessor :type, :title, :message

  TYPES = {
    success: "success",
    error: "error",
    warning: "warning",
    info: "info"
  }.freeze

  def initialize(type:, title:, message: nil)
    @type = type
    @title = title
    @message = message
  end

  def to_hash
    {
      type: type,
      title: title,
      message: message
    }
  end
end
