# frozen_string_literal: true

class PulacCerulloTask < Task
  # Skip unique verification
  def verify_org_task_unique; end

  def self.label
    "Pulac-Cerullo"
  end
end
