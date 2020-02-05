# frozen_string_literal: true

require "console_tree_renderer"

# Usage instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRenderModule
  def self.new_renderer # rubocop:disable all
    ConsoleTreeRenderer::ConsoleRenderer.new.tap do |ttr|
      ttr.config.value_funcs_hash.merge!(
        CRE_DATE: ->(task) { task.created_at&.strftime("%Y-%m-%d") },
        CRE_TIME: ->(task) { task.created_at&.strftime("%H-%M-%S") },
        UPD_DATE: ->(task) { task.updated_at&.strftime("%Y-%m-%d") },
        UPD_TIME: ->(task) { task.updated_at&.strftime("%H-%M-%S") },
        CLO_DATE: ->(task) { task.updated_at&.strftime("%Y-%m-%d") },
        CLO_TIME: ->(task) { task.updated_at&.strftime("%H-%M-%S") },
        ASGN_DATE: ->(task) { task.created_at&.strftime("%Y-%m-%d") },
        ASGN_TIME: ->(task) { task.created_at&.strftime("%H-%M-%S") },
        ASGN_BY: lambda { |task|
          ConsoleTreeRenderer.send_chain(task, [:assigned_by, :type])&.to_s ||
            ConsoleTreeRenderer.send_chain(task, [:assigned_by, :name])&.to_s ||
            ConsoleTreeRenderer.send_chain(task, [:assigned_by, :css_id])&.to_s
        },
        ASGN_TO: lambda { |task|
          ConsoleTreeRenderer.send_chain(task, [:assigned_to, :type])&.to_s ||
            ConsoleTreeRenderer.send_chain(task, [:assigned_to, :name])&.to_s ||
            ConsoleTreeRenderer.send_chain(task, [:assigned_to, :css_id])&.to_s
        }
      )
      ttr.config.default_atts = [:id, :status, :ASGN_BY, :ASGN_TO, :updated_at]
      ttr.config.heading_label_template = lambda { |appeal|
        docket = (defined?(appeal.docket_type) && appeal.docket_type) ||
                 (defined?(appeal.docket_name) && appeal.docket_name)
        "#{appeal.class.name} #{appeal.id} (#{docket}) "
      }
      ttr.config.custom["show_all_tasks"] = true
    end
  end

  def self.global_renderer
    @global_renderer ||= new_renderer
  end

  # for easy access to the global_renderer from an appeal or task instance
  # :reek:UtilityFunction
  def global_renderer
    TaskTreeRenderModule.global_renderer
  end

  def treee(*atts, **kwargs)
    puts tree(*atts, **kwargs) # rubocop: disable Rails/Output
  end

  # :reek:FeatureEnvy
  def tree(*atts, **kwargs)
    kwargs[:highlight_row] = Task.find(kwargs.delete(:highlight)) if kwargs[:highlight]
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.tree_str(self, *atts, **kwargs)
  end

  # :reek:FeatureEnvy
  def tree_hash(*atts, **kwargs)
    kwargs[:highlight_row] = Task.find(kwargs.delete(:highlight)) if kwargs[:highlight]
    renderer = kwargs.delete(:renderer) || global_renderer
    renderer.tree_hash(self, *atts, **kwargs)
  end

  ## The following are needed by ConsoleTreeRenderer

  # called by config.heading_label_template
  def heading_object(_config)
    is_a?(Task) ? appeal : self
  end

  # called by rows and used by config.value_funcs_hash
  def row_objects(_config)
    is_a?(Task) ? appeal.tasks : tasks
  end

  def row_label(_config)
    self.class.name
  end

  def row_children(_config)
    children.order(:id)
  end

  # returns RootTask and root-level tasks (which are not under that RootTask)
  def rootlevel_rows(config)
    @rootlevel_rows ||= is_a?(Task) ? [self] : appeal_children(self, config)
  end

  private

  # return all root-level tasks that are considered part of this appeal
  def appeal_children(appeal, config)
    roottask_ids = appeal.tasks.where(parent_id: nil).pluck(:id)
    if config.custom["show_all_tasks"]
      # in some tests, parent tasks are (erroneously) not in the same appeal
      task_ids = appeal.tasks.reject { |tsk| tsk.parent&.appeal_id == appeal.id }.pluck(:id)
    end
    roottask_ids |= task_ids if task_ids
    Task.where(id: roottask_ids.compact.sort)
  end
end
