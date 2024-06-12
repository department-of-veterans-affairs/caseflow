# frozen_string_literal: true

class RemovePackageDocumentTypeTable < Caseflow::Migration
  def up
    safety_assured do
      drop_table :package_document_types
    end
  end

  def down
    safety_assured do
      create_table :package_document_types do |t|
        t.string :name
        t.boolean :active, default: true
        t.timestamps
      end
    end
  end
end
