# frozen_string_literal: true

class ApplicationDecorator < SimpleDelegator
  alias_method :object, :__getobj__
end
