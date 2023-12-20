# frozen_string_literal: true

class IndexHearingsOnDisposition < Caseflow::Migration
  def change
    add_safe_index :hearings, [:disposition]
  end
end
