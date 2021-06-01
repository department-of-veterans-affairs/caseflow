class AddOriginalRequestTypeToAppeal < Caseflow::Migration
  def change
    add_column :appeals,
      :original_request_type,
      :string,
      comment: "The hearing type preference for an appellant before any changes were made in Caseflow"
  end
end
