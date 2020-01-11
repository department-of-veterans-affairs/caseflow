# frozen_string_literal: true

# Usage instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRenderModule
  def self.new_renderer
    TaskTreeRenderer.new.tap do |ttr|
      ttr.config.value_funcs_hash.merge!(
        CRE_DATE: ->(task) { task.created_at&.strftime("%Y-%m-%d") || "" },
        CRE_TIME: ->(task) { task.created_at&.strftime("%H-%M-%S") || "" },
        UPD_DATE: ->(task) { task.updated_at&.strftime("%Y-%m-%d") || "" },
        UPD_TIME: ->(task) { task.updated_at&.strftime("%H-%M-%S") || "" },
        CLO_DATE: ->(task) { task.updated_at&.strftime("%Y-%m-%d") || "" },
        CLO_TIME: ->(task) { task.updated_at&.strftime("%H-%M-%S") || "" },
        ASGN_DATE: ->(task) { task.created_at&.strftime("%Y-%m-%d") || "" },
        ASGN_TIME: ->(task) { task.created_at&.strftime("%H-%M-%S") || "" }
      )
    end
  end

  @global_renderer = new_renderer

  def self.static_renderer
    @global_renderer
  end

  # for easy access to the global_renderer from an appeal or task instance
  def global_renderer
    TaskTreeRenderModule.static_renderer
  end

  def treee(*atts, **kwargs)
    puts tree(*atts, **kwargs)
  end

  def tree(*atts, **kwargs)
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.tree_str(self, *atts, **kwargs)
  end

  def tree_hash(*atts, **kwargs)
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.tree_hash(self, *atts, **kwargs)
  end

end
