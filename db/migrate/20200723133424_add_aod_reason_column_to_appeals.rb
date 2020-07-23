class AddAodReasonColumnToAppeals < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals, :aod_reason, :string, :default => nil, comment: "If not nil, the reason for advance-on-docket, such as 'motion' (see advance_on_docket_motions table) or 'age' if due to claimant's age."
  end
end
