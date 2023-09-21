class AddMetricTypeIndexToMetrics < Caseflow::Migration
  def change
    add_safe_index :metrics, :metric_type
    add_safe_index :metrics, :created_at
  end
end
