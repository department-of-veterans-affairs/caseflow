# frozen_string_literal: true

class FieldVso < Vso
  after_create :add_vso_config

  def queue_tabs
    [
      tracking_tasks_tab
    ]
  end

  private

  def add_vso_config
    VsoConfig.create!(organization: self, ihp_dockets: [])
  end
end
