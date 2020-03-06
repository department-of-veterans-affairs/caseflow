# frozen_string_literal: true

module HasTaskHistory
  extend ActiveSupport::Concern

  def history
    AppealTaskHistory.new(appeal: self)
  end
end
