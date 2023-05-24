class AddIndexToMembershipRequests < Caseflow::Migration
  def change
    add_safe_index :membership_requests, [:status,:organization_id, :requestor_id], name: 'index_membership_requests_on_status_and_association_ids', unique: true, where: "status = 'assigned'"
  end
end
