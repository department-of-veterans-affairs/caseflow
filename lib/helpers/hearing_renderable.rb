# frozen_string_literal: true

module HearingRenderable
  extend ActiveSupport::Concern

  def render_hearing(*atts)
    HearingRenderer.render(self, *atts)
  end
end
