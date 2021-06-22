# frozen_string_literal: true

##
# Class to help create an ERD (entity relationship diagram) documentation using GraphViz.

# rubocop:disable Metrics/ModuleLength
module ErdGraphStyling
  DECISION_REVIEW_POLYTYPES = %w[
    decision_review_type review_type decision_review_remanded_type
    appeal_type
    original_decision_review_type
    record_type
  ].freeze

  # Records that can act as join tables (has foreign keys to exactly 2 other tables)
  # Would be great to automatically identify these
  JOIN_TABLE_RECORDS = %w[
    OrganizationsUser
    RequestDecisionIssue
    IhpDraft
    JudgeTeamRole
    HearingTaskAssociation AppealStreamSnapshot HearingView HearingIssueNote SentHearingEmailEvent
    DocumentView DocumentsTag Annotation
    AppealView
    ClaimsFolderSearch
    Message
  ].freeze

  NODE_STYLES = {
    abstract_records: {
      node_names: %w[DecisionReview ClaimReview],
      attribs: {
        shape: "record",
        style: "dashed"
      }
    },
    decision_reviews: {
      node_names: DECISION_REVIEW_POLYTYPES +
                  %w[Appeal SupplementalClaim HigherLevelReview LegacyAppeal DecisionReview ClaimReview],
      attribs: {
        fillcolor: "#ffff00", # yellow
        style: "filled"
      }
    },
    hearing_appeal_stream_snapshot: {
      # Make record type's non-intuitive tablename more obvious
      node_names: ["AppealStreamSnapshot"],
      attribs: {
        label: "AppealStreamSnapshot\n(a.k.a. hearing_appeal_stream_snapshots)"
      }
    },
    join_table_records: {
      node_names: JOIN_TABLE_RECORDS,
      attribs: {
        fillcolor: "#f2f2f2",
        style: "filled",
        shape: "component",
        color: "#aaaaaa"
      }
    }
  }.freeze

  # :reek:NestedIterator
  def style_nodes(graph)
    NODE_STYLES.values.each do |styling|
      styling[:node_names].each do |node_name|
        graph.get_node(node_name) do |node|
          styling[:attribs].each { |key, value| node[key] = value }
        end
      end
    end

    style_nodes_by_category(graph)
  end

  private

  # Records that indicate completion of a significant step
  COMPLETION_RECORDS = %w[
    JudgeCaseReview AttorneyCaseReview
    DecisionDocument VbmsUploadedDocument
    DecisionIssue
    ClaimEstablishment
    BoardGrantEffectuation
  ].freeze

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def style_nodes_by_category(graph)
    graph.each_node do |name, node|
      if COMPLETION_RECORDS.include?(name)
        node[:shape] = "note"
        node[:style] = "filled"
        node[:fillcolor] = "#ff5050"
      elsif apply_ancestor_styling(name, node)
      elsif name.starts_with?("Ramp")
        node[:style] = "filled"
        node[:fillcolor] = "#cc99ff"
      elsif name.ends_with?("Availability")
        node[:style] = "filled"
        node[:fillcolor] = "#00aaff"
      elsif name.include?("Hearing") || %w[WorksheetIssue Transcription].include?(name)
        node[:style] = "filled" unless node[:style]
        node[:fillcolor] = "#66ccff" unless node[:fillcolor]
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def apply_ancestor_styling(name, node)
    class_ancestors = begin
                        name.constantize.ancestors
                      rescue StandardError
                        nil
                      end

    class_ancestors&.find { |ancestor| subclass_styling_config[ancestor] }&.tap do |ancestor|
      subclass_styling_config[ancestor].each { |key, value| node[key] = value }
    end
  end

  # rubocop:disable Metrics/MethodLength
  def subclass_styling_config
    @subclass_styling_config ||= {
      # Specify colors in hex for consistent colors between png and svg files
      Organization => {
        fillcolor: "#d9d9ff",
        style: "filled"
      },
      Task => {
        fillcolor: "#00ff00",
        style: "filled"
      },
      Intake => {
        shape: "cds",
        height: 0.7,
        fillcolor: "#ffffcc",
        style: "filled"
      },
      Claimant => {
        fillcolor: "#a9a9a9",
        style: "filled"
      },
      RequestIssue => {
        fillcolor: "#ffa500", # orange
        style: "filled"
      },
      SchedulePeriod => {
        fillcolor: "#00ffff", # cyan
        style: "filled"
      },
      Dispatch::Task => {
        fillcolor: "#adff2f", # greenyellow
        style: "filled"
      }
    }
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
