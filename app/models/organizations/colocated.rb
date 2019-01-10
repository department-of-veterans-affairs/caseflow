class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Staff", url: "vlj-support")
  end

  def next_assignee(task_class = nil, appeal = nil)
    ColocatedTaskDistributor.new.next_assignee(task_class, appeal)
  end
end
