# frozen_string_literal: true

# Public: Concern that will add the created by and updated by triggers to a model.
# This module will connect the method assign_created_by_user to the model's
# before_create lifecycle method to ensure when the model is inserting a
# row in the database the model will leverage teh use in the the request store
# This module will aslo connect the method assign_updated_by_user to the model's
# before_update lifecycle method to ensure when the model is updating a
# row in the database the model will leverage the user in the the request store
module CreatedAndUpdatedByUserConcern
  extend ActiveSupport::Concern
  included do
    belongs_to :created_by, class_name: "User"

    before_create :assign_created_by_user

    belongs_to :updated_by, class_name: "User", optional: true

    before_update :assign_updated_by_user
  end

  private

  # Description: Method to set the created by user when inserting a new row
  # If rails is being run with the test environment confirguration (RSPEC)
  # then the system user will be used for the the created user else
  # if any other configuration the current user in the request store will be used
  # Params: N/A
  #
  # Returns: N/A
  def assign_created_by_user
    self.created_by ||= (Rails.current_env.to_s != "test") ? RequestStore.store[:current_user] : User.system_user
  end

  # Description: Method to set the updated by user when inserting a new row
  # If the current user is set in teh request store that user will be passed in for
  # the updated by user
  # Params: N/A
  #
  # Returns: N/A
  def assign_updated_by_user
    self.updated_by = RequestStore.store[:current_user] if RequestStore.store[:current_user].present?
  end
end
