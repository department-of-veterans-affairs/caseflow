class AddPeopleName < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :first_name, :string, comment: "Person first name, cached from BGS"
    add_column :people, :last_name, :string, comment: "Person last name, cached from BGS"
    add_column :people, :middle_name, :string, comment: "Person middle name, cached from BGS"
    add_column :people, :name_suffix, :string, comment: "Person name suffix, cached from BGS"
  end
end
