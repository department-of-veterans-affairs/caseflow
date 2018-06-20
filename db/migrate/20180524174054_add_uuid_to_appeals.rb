class AddUuidToAppeals < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      add_column :appeals, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    end
  end
end
