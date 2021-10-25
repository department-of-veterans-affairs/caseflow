# frozen_string_literal: true

require_relative "check_task_tree"

module ProductionConsoleMethods
  def check_task_tree(appeal, verbose: true)
    CheckTaskTree.call(appeal, verbose: verbose)
  end
end
