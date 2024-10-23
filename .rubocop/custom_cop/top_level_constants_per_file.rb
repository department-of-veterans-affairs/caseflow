# frozen_string_literal: true

module RuboCop
  module CustomCop
    class TopLevelConstantsPerFile < RuboCop::Cop::Cop
      MSG = "Multiple top-level constants detected in one file. The autoloader expects one top-level constant per file."

      def investigate(processed_source)
        return unless processed_source

        # If more than one top-level constant in the file, add offense on the second one
        if top_level_constant_nodes.size > 1
          add_offense(top_level_constant_nodes[1], message: MSG)
        end
      end

      private

      def top_level_constant_nodes
        @top_level_constant_nodes ||=
          processed_source.ast.each_node(:class, :module).select { |node| top_level_constant?(node) }
      end

      def top_level_constant?(node)
        # node is not nested within a class or module node?
        node.ancestors.none? { |ancestor| ancestor.class_type? || ancestor.module_type? }
      end
    end
  end
end
