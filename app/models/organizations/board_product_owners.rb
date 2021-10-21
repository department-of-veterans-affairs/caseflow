# frozen_string_literal: true

class BoardProductOwners < Organization
  def self.singleton
    BoardProductOwners.first || BoardProductOwners.create(name: "Board Product Owners", url: "product_owners")
  end

  def can_receive_task?(_task)
    false
  end
end
