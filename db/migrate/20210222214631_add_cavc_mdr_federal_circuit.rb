# frozen_string_literal: true

class AddCavcMdrFederalCircuit < Caseflow::Migration
  def change
    add_column :cavc_remands, :federal_circuit, :boolean,
               comment: "Whether the case has been appealed to the US Court of Appeals for the Federal Circuit"
  end
end
