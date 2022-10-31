# frozen_string_literal: true

module CreatedAndUpdatedByUserConcern
  extend ActiveSupport::Concern
  included do
    belongs_to :created_by, class_name: "User"

    before_create :assign_created_by_user

    belongs_to :updated_by, class_name: "User", optional: true

    before_update :assign_updated_by_user
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore.store[:current_user]
  end

  def assign_updated_by_user
    self.updated_by = RequestStore.store[:current_user] if RequestStore.store[:current_user].present?
  end
end
