# frozen_string_literal: true

module UpdatedByUserConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :updated_by, class_name: "User", optional: true

    before_save :assign_updated_by_user
  end

  private

  def assign_updated_by_user
    return if RequestStore.store[:current_user] == User.system_user && updated_by.present?

    self.updated_by = RequestStore.store[:current_user] if RequestStore.store[:current_user].present?
  end
end
