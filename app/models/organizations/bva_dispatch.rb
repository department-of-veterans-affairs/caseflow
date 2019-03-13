# frozen_string_literal: true

class BvaDispatch < Organization
  def self.singleton
    BvaDispatch.first || BvaDispatch.create(name: "Board Dispatch", url: "board-dispatch")
  end

  def next_assignee(options = {})
    BvaDispatchTaskDistributor.new.next_assignee(options)
  end
end
