# frozen_string_literal: true

class ApplicationDecorator < SimpleDelegator
  alias object __getobj__
end
