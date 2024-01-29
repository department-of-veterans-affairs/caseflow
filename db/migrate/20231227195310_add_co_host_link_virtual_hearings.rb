class AddCoHostLinkVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :co_host_hearing_link, :string
  end
end
