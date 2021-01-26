class AddChangedHearingRequestTypeToAppeal < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals,
               :changed_request_type,
               :string,
               comment: "The new hearing type preference for an appellant that needs a hearing scheduled"
  end
end
