# frozen_string_literal: true

module CreatedByUserConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: "User"

    before_validation :assign_created_by_user, on: :create
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore.store[:current_user]
  end
end
