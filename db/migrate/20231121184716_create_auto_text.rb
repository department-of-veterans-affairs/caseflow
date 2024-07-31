class CreateAutoText < Caseflow::Migration
  def change
    create_table :auto_texts do |t|
      t.string :name
    end
  end
end
