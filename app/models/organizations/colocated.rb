class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Staff", url: "vlj-support")
  end

  def next_assignee(_task_type)
    ColocatedTaskAssigneeFactory.new.next_assignee
  end
end
