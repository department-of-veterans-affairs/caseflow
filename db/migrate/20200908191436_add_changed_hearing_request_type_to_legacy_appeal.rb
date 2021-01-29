class AddChangedHearingRequestTypeToLegacyAppeal < Caseflow::Migration
  def change
    add_column :legacy_appeals,
               :changed_request_type,
               :string,
               comment: "The new hearing type preference for an appellant that had previously requested a travel board hearing"
  end
end
