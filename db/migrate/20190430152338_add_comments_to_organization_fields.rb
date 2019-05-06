# frozen_string_literal: true

class AddCommentsToOrganizationFields < ActiveRecord::Migration[5.1]
  def change
    change_column_comment(:organizations, :participant_id, "Organizations BGS partipant id")
    change_column_comment(:organizations, :role, "Role users in organization must have, if present")
    change_column_comment(:organizations, :type, "Single table inheritance")
    change_column_comment(:organizations, :url, "Unique portion of the organization queue url")
  end
end
