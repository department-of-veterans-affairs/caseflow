# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRenderModule
  def treee(*atts, **kwargs)
    puts tree(*atts, **kwargs)
  end

  def tree(*atts, **kwargs)
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.as_string(self, *atts, **kwargs)
  end

  def tree_hash(*atts, **kwargs)
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.tree_hash(self, *atts, **kwargs)
  end

  def global_renderer
    @@global_renderer ||= new_renderer
  end

  def new_renderer
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

  def compact_treee(*atts, **kwargs)
    kwargs[:renderer] ||= new_renderer
    kwargs[:renderer].compact
    kwargs[:renderer].config.default_atts = [:id, :status, :ASGN_BY, :ASGN_TO, :UPD_DATE]
    treee(*atts, **kwargs)
  end
end
