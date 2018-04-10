class AddCancellationReasonToIntake < ActiveRecord::Migration[5.1]
  def change
    add_column :intakes, :cancel_reason, :string
    add_column :intakes, :cancel_other, :string
  end
end
