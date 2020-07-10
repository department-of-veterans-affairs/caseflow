# frozen_string_literal: true

class AppealHistory
  include ActiveModel::Model

  INVALID_TYPES = ["Designation of Record"].freeze

  attr_accessor :vbms_id

  def appeals
    @appeals ||= fetch_appeals
  end

  def appeal_series
    @appeal_series ||= fetch_appeal_series
  end

  private

  def fetch_appeals
    LegacyAppeal.repository.appeals_by_vbms_id_with_preloaded_status_api_attrs(vbms_id)
      .reject { |appeal| INVALID_TYPES.include? appeal.type }
  end

  def fetch_appeal_series
    if needs_update?
      destroy_appeal_series
      generate_appeal_series
    end

    appeals.group_by(&:appeal_series).map do |series, appeals_for_series|
      # We replace the associated appeals with the appeals we've preloaded
      series.appeals.replace(appeals_for_series)
      series
    end
  end

  def needs_update?
    return false if appeals.empty?
    return true if appeals.any? { |appeal| appeal.appeal_series.nil? }

    # If a new appeal has been merged, we need to regenerate the series
    appeals.count(&:merged?) != appeals.first.appeal_series.merged_appeal_count
  end

  def destroy_appeal_series
    # Since we have "dependent: :nullify" set on AppealSeries, this
    # will null out all the foreign appeal_series_ids on appeals.
    AppealSeries.where(id: appeals.map(&:appeal_series_id).uniq).destroy_all
  end

  def generate_appeal_series
    merge_table = {}
    series_table = {}

    # Each appeal tree gets a series ID; assign all of its descendant nodes that ID.
    appeal_tree_roots.each_with_index do |root, sid|
      traverse_appeal_tree(root, sid) { |node| node[:series_id] = sid }

      merge_table[sid] = sid
    end

    # Combine series if they have been merged.
    merged = merged_appeal_tree_nodes_with_target

    merged.each do |node|
      merge_table[node[:series_id]] = node[:merge_target][:series_id] if node[:merge_target]
    end

    merge_table.values.uniq.each do |sid|
      # We keep track of the count of merged appeals in a series because if
      # further merges take place, we need to regenerate the appeal series.
      series_table[sid] = AppealSeries.create(merged_appeal_count: merged.length)
    end

    appeal_tree_nodes.each do |node|
      # Set the series, joining through the merge table to the series table.
      appeal_series = series_table[merge_table[node[:series_id]]]
      appeal_series.appeals << node[:appeal]
      # If any node is marked as incomplete, the series is marked as incomplete.
      appeal_series.update(incomplete: true) if node[:incomplete]
    end

    burn_appeal_trees
  end

  def appeal_tree_nodes
    grow_appeal_trees unless @nodes
    @nodes
  end

  def appeal_tree_roots
    grow_appeal_trees unless @roots
    @roots
  end

  def grow_appeal_trees
    # Build a tree linking child appeals to their parents
    @nodes = appeals.map do |appeal|
      node = { appeal: appeal, children: [] }
      next node if appeal.type == "Original"

      parent = find_parent_appeal(appeal)

      if parent
        node[:parent_appeal] = parent
      else
        node[:incomplete] = true
      end

      node
    end

    @roots, children = @nodes.partition { |node| node[:parent_appeal].nil? }

    # Invert the tree, so we can traverse it downward later
    children.each do |child|
      parent = @nodes.find { |node| node[:appeal] == child[:parent_appeal] }
      parent[:children].push(child)
      child.delete(:parent_appeal)
    end
  end

  def burn_appeal_trees
    remove_instance_variable :@nodes
    remove_instance_variable :@roots
  end

  def traverse_appeal_tree(node, sid)
    yield(node)
    node[:children].each do |child|
      traverse_appeal_tree(child, sid) { |child_node| child_node[:series_id] = sid }
    end
  end

  def find_parent_appeal(appeal)
    if %w[B W P].include? appeal.vacols_id[-1]
      # Appeals that are created for the sole purpose of recording a post-remand field disposition
      # have the same vacols_id as their parent, just with the disposition code appended.
      parent_id = appeal.vacols_id[0...-1]
      appeals.find { |candidate| candidate.vacols_id == parent_id }
    else
      find_parent_appeal_by_decision_date_and_issues(appeal)
    end
  end

  def find_parent_appeal_by_decision_date_and_issues(appeal)
    # Prevents loops
    return nil if appeal.prior_decision_date.nil? ||
                  (appeal.decision_date && appeal.prior_decision_date >= appeal.decision_date)

    candidates_by_date = appeals.select do |candidate|
      candidate.decision_date == appeal.prior_decision_date
    end

    return candidates_by_date.first if candidates_by_date.length == 1

    # If there are multiple parent candidates, search for matching issue_categories.
    candidates_by_issue = candidates_by_date.reject do |candidate|
      (appeal.issue_categories & candidate.issue_categories).empty?
    end

    return candidates_by_issue.first if candidates_by_issue.length == 1
  end

  def merged_appeal_tree_nodes_with_target
    # The descriptions of issues on an appeal that has had another appeal merged
    # into it are appended with the date and vacols_id of the source appeal.

    merged = appeal_tree_nodes.select { |node| node[:appeal].merged? }

    merge_strs = merged.map do |node|
      date = node[:appeal].decision_date&.strftime("%m/%d/%y")
      folder = node[:appeal].vacols_id
      "From appeal merged on #{date} (#{folder})"
    end

    merged.each_with_index do |node, i|
      # If the description exceeds 100 characters, the merge string will be truncated.
      # Incrementally add add characters until we get to a unique merge string to avoid some cases of truncation.
      abbr_merge_str = ""
      abbr_len = 30 # The minimum truncated length that can be searched for (must include at least a full date)

      loop do
        abbr_merge_str = merge_strs[i][0...abbr_len]
        cnt = merge_strs.count { |str| str.start_with?(abbr_merge_str) }
        break if cnt == 1 || abbr_len == merge_strs[i].length

        abbr_len += 1
      end

      node[:merge_target] = find_merge_target(abbr_merge_str)
    end
  end

  def find_merge_target(merge_str)
    matches = appeal_tree_nodes.select do |candidate|
      candidate[:appeal].issues.any? do |issue|
        issue.note.try(:include?, merge_str)
      end
    end

    return matches.first if matches.length == 1
  end

  class << self
    def for_api(vbms_id:)
      new(vbms_id: vbms_id)
        .appeal_series
        .sort_by(&:api_sort_key)
    end
  end
end
