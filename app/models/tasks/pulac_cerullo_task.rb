# frozen_string_literal: true

class PulacCerulloTask < GenericTask
  # Skip unique verification
  def verify_org_task_unique; end

  def label
    "Pulac-Cerullo"
  end
end
