class AddDefaultUuidForBatchProcesses < Caseflow::Migration
  def change
    change_column_default :batch_processes, :batch_id, from: nil, to: "uuid_generate_v4()"
  end
end
