class AddHostLinkAndGuestLinkToVirtualHearing < Caseflow::Migration
  def change
    add_column :virtual_hearings, :host_hearing_link, :string, comment: "Link used by judges to join virtual hearing conference"
    add_column :virtual_hearings, :guest_hearing_link, :string, comment: "Link used by appellants and/or representatives to join virtual hearing conference"
  end
end

