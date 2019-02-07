class BvaDispatch < Organization
  def self.singleton
    BvaDispatch.first || BvaDispatch.create(name: "Board Dispatch")
  end

  def next_assignee(options = {})
    BvaDispatchTaskDistributor.new.next_assignee(options)
  end
end
