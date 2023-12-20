# frozen_string_literal: true

module IntakeRenderable
  extend ActiveSupport::Concern

  def render_intake(*atts)
    IntakeRenderer.render(self, *atts)
  end
end
