class CreateHearingsSupervisors < ActiveRecord::Migration[6.1]
  def change
    create_table :hearings_supervisors do |t|

      t.timestamps
    end
  end
end
