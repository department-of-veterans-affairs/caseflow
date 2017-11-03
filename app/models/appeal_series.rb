class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  class << self
    def appeal_series_by_vbms_id(vbms_id)
      appeals = Appeal.repository.appeals_by_vbms_id(vbms_id)

      return [] if appeals.empty?

      no_series_cnt = appeals.count { |appeal| appeal.appeal_series.nil? }
      needs_update = no_series_cnt > 0

      if !needs_update
        merge_cnt = appeals.count { |appeal| appeal.disposition == "Merged Appeal" }
        needs_update = merge_cnt != appeals.first.appeal_series.merged_appeal_count
      end

      appeals = generate_appeal_series(appeals) if needs_update

      appeals.map(&:appeal_series).uniq
    end

    private

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def generate_appeal_series(appeals)
      appeals.map(&:appeal_series).compact.uniq.each(&:destroy)

      # Build a tree linking child appeals to their parents
      nodes = appeals.map do |appeal|
        node = { appeal: appeal, children: [] }
        next node if appeal.type == "Original"

        # Attempt to match post-remand appeals on the vacols_id
        if %w(B W).include? appeal.vacols_id[-1]
          parent_id = appeal.vacols_id[0...-1]
          parent_candidates = appeals.select { |candidate| candidate.vacols_id == parent_id }

          if parent_candidates.length == 1
            node[:parent_appeal] = parent_candidates.first
          else
            node[:incomplete] = true
          end

          next node
        end

        # Attempt to match on date, prevent loops
        if appeal.prior_decision_date.nil? || appeal.prior_decision_date >= appeal.decision_date
          node[:incomplete] = true
          next node
        end

        parent_candidates = appeals.select do |candidate|
          candidate.decision_date == appeal.prior_decision_date
        end

        if parent_candidates.empty?
          node[:incomplete] = true
          next node
        elsif parent_candidates.length == 1
          node[:parent_appeal] = parent_candidates.first
          next node
        end

        # More than one parent with the prior decision date, attempt to match on issues
        parent_candidates.select! do |candidate|
          !(appeal.issue_codes & candidate.issue_codes).empty?
        end

        if parent_candidates.length == 1
          node[:parent_appeal] = parent_candidates.first
        else
          node[:incomplete] = true
        end

        node
      end

      roots, children = nodes.partition { |node| node[:parent_appeal].nil? }

      # Invert the tree
      children.each do |child|
        parent = nodes.find { |node| node[:appeal] == child[:parent_appeal] }
        parent[:children].push(child)
        child.delete(:parent_appeal)
      end

      merge_table = {}
      series_table = {}

      traverse = lambda do |node, &block|
        block.call(node)
        node[:children].each { |child| traverse.call(child, &block) }
      end

      # Each root gets a series ID, assign all of its descendants that ID
      roots.each_with_index do |root, sid|
        traverse.call(root) do |node|
          node[:series_id] = sid
        end

        merge_table[sid] = sid
      end

      # Combine series if they have been merged
      merged = nodes.select { |node| node[:appeal].disposition == "Merged Appeal" }

      merge_cnt = merged.length

      merge_strs = merged.map do |node|
        date = node[:appeal].decision_date.strftime("%m/%d/%y")
        folder = node[:appeal].vacols_id
        "From appeal merged on #{date} (#{folder})"
      end

      # Search issue descriptions for text indicating the source appeal
      # The issue description field has a character limit, so the note may be truncated
      merged.each_with_index do |node, i|
        abbr_merge_str = ""
        abbr_len = 23 # The minimum truncated length that can be searched for

        loop do
          abbr_merge_str = merge_strs[i][0...abbr_len]
          cnt = merge_strs.count { |str| str.start_with?(abbr_merge_str) }
          break if cnt == 1 || abbr_len == merge_strs[i].length
          abbr_len += 1
        end

        destination_candidates = nodes.select do |candidate|
          candidate[:appeal].issues.any? do |issue|
            issue.description.include?(abbr_merge_str)
          end
        end

        if destination_candidates.length == 1
          merge_table[node[:series_id]] = destination_candidates.first[:series_id]
        end
      end

      merge_table.values.uniq.each do |sid|
        # If the number of merges changes, the series will need to be regenerated
        series_table[sid] = create(merged_appeal_count: merge_cnt)
      end

      nodes.each do |node|
        # Set the series, joining through the merge table to the series table
        node[:appeal].update(appeal_series: series_table[merge_table[node[:series_id]]])
        # If any node is marked as complete, the series is marked as incomplete
        node[:appeal].appeal_series.update(incomplete: true) if node[:incomplete]
      end

      appeals
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
