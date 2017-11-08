class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  class << self
    def appeal_series_by_vbms_id(vbms_id)
      appeals = Appeal.repository.appeals_by_vbms_id(vbms_id)

      return [] if appeals.empty?

      appeals = generate_appeal_series(appeals) if needs_update(appeals)

      appeals.map(&:appeal_series).uniq
    end

    private

    def needs_update(appeals)
      return true if appeals.any? { |appeal| appeal.appeal_series.nil? }

      # If a new appeal has been merged, we need to regenerate the series
      appeals.count(&:merged?) != appeals.first.appeal_series.merged_appeal_count
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def generate_appeal_series(appeals)
      # Before we get started, delete all the existing appeal series for our appeals
      # Since we have "dependent: :nullify" set above, this will null out all the foreign appeal_series_ids on appeals
      appeals.map(&:appeal_series).compact.uniq.each(&:destroy)

      # Build a tree linking child appeals to their parents
      nodes = appeals.map do |appeal|
        node = { appeal: appeal, children: [] }
        next node if appeal.type == "Original"

        if %w(B W).include? appeal.vacols_id[-1]
          parent_id = appeal.vacols_id[0...-1]
          parent = appeals.find { |candidate| candidate.vacols_id == parent_id }
        else
          parent = find_parent_by_date_and_issues(appeal, appeals)
        end

        if parent
          node[:parent_appeal] = parent
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
      # The description of issues that are merged are appended with the date and vacols_id of the source appeal
      merged = nodes.select { |node| node[:appeal].merged? }

      merge_cnt = merged.length

      merge_strs = merged.map do |node|
        date = node[:appeal].decision_date.strftime("%m/%d/%y")
        folder = node[:appeal].vacols_id
        "From appeal merged on #{date} (#{folder})"
      end

      merged.each_with_index do |node, i|
        # If the description exceeds 100 characters, the merge string will be truncated
        # We incrementally add add characters until we get to a unique merge string to avoid some cases of truncation
        abbr_merge_str = ""
        abbr_len = 30 # The minimum truncated length that can be searched for (must include at least a full date)

        loop do
          abbr_merge_str = merge_strs[i][0...abbr_len]
          cnt = merge_strs.count { |str| str.start_with?(abbr_merge_str) }
          break if cnt == 1 || abbr_len == merge_strs[i].length
          abbr_len += 1
        end

        target = find_merge_target(abbr_merge_str, nodes)

        merge_table[node[:series_id]] = target[:series_id] if target
      end

      merge_table.values.uniq.each do |sid|
        # If the number of merges changes, the series will need to be regenerated
        series_table[sid] = create(merged_appeal_count: merge_cnt)
      end

      nodes.each do |node|
        # Set the series, joining through the merge table to the series table
        node[:appeal].update(appeal_series: series_table[merge_table[node[:series_id]]])
        # If any node is marked as incomplete, the series is marked as incomplete
        node[:appeal].appeal_series.update(incomplete: true) if node[:incomplete]
      end

      appeals
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def find_parent_by_date_and_issues(appeal, appeals)
      # Prevent loops
      return nil if appeal.prior_decision_date.nil? || appeal.prior_decision_date >= appeal.decision_date

      candidates_by_date = appeals.select do |candidate|
        candidate.decision_date == appeal.prior_decision_date
      end

      return candidates_by_date.first if candidates_by_date.length == 1

      candidates_by_issue = candidates_by_date.select do |candidate|
        !(appeal.issue_codes & candidate.issue_codes).empty?
      end

      return candidates_by_issue.first if candidates_by_issue.length == 1
    end

    def find_merge_target(merge_str, nodes)
      matches = nodes.select do |candidate|
        candidate[:appeal].issues.any? do |issue|
          issue.description.include?(merge_str)
        end
      end

      return matches.first if matches.length == 1
    end
  end
end
