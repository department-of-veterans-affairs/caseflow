# frozen_string_literal: true

class FieldVso < Vso
  after_create :add_vso_config

  private

  def add_vso_config
    VsoConfig.create!(organization: self, ihp_dockets: [])
  end
end
