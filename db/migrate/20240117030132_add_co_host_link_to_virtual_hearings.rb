class AddCoHostLinkToVirtualHearings < Caseflow::Migration
  def change
    add_column :virtual_hearings, :co_host_hearing_link, :string
  end
end
