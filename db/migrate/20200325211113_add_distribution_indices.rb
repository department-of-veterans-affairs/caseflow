class AddDistributionIndices < Caseflow::Migration
  def change
    add_safe_index :appeals, :docket_type
    add_safe_index :appeals, :established_at
    add_safe_index :advance_on_docket_motions, :granted
  end
end
