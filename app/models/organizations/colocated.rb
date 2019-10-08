# frozen_string_literal: true

class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Staff", url: "vlj-support")
  end

  def next_assignee(options = {})
    ColocatedTaskDistributor.new.next_assignee(options)
  end

  def use_task_pages_api?
    true
  end
end
