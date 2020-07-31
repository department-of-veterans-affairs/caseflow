# frozen_string_literal: true

module IntakeRenderable
  extend ActiveSupport::Concern

  def structure_render(*atts)
    IntakeRenderer.render(self, *atts)
  end
end
