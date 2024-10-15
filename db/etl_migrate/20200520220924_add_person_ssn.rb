class AddPersonSsn < Caseflow::Migration
  def change
    add_column :people, :ssn, :string, comment: "Person Social Security Number, cached from BGS"
    add_safe_index :people, [:ssn]
  end
end
