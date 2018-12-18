class BvaDispatch < Organization
  def self.singleton
    BvaDispatch.first || BvaDispatch.create(name: "Board Dispatch")
  end
end
