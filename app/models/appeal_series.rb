class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  def latest_appeal
    return @latest_appeal if @latest_appeal

    active = appeals.select { |appeal| appeal.active? }

    if active.length > 1
      active.sort! { |x, y| y.last_location_change_date <=> x.last_location_change_date }
    end

    return active.first if active.length > 0

    @latest_appeal = appeals.sort { |x, y| y.decision_date <=> x.decision_date }.first
  end

  def vacols_id
    latest_appeal.vacols_id
  end

  def active?
    latest_appeal.active?
  end

  def type_code
    latest_appeal.type_code || 'other'
  end

  def api_sort_date
    appeals.map(&:nod_date).min || DateTime::Infinity.new
  end

  def events
    appeals.flat_map(&:events).uniq
  end

  class << self
    def for_api(appellant_ssn:)
      fail Caseflow::Error::InvalidSSN if !appellant_ssn || appellant_ssn.length != 9

      appeal_series_by_vbms_id(Appeal.vbms_id_for_ssn(appellant_ssn))
        .sort_by(&:api_sort_date)
    end

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
      where(id: appeals.map(&:appeal_series_id).uniq).destroy_all

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

      # Invert the tree, so we can traverse it downward later
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
      # The descriptions of issues on an appeal that has had another appeal merged
      # into it are appended with the date and vacols_id of the source appeal.

      # Appeals that have been merged into other appeals
      merged = nodes.select { |node| node[:appeal].merged? }

      merge_count = merged.length

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
        # We keep track of the count of merged appeals in a series because if
        # further merges take place, we need to regenerate the appeal series.
        series_table[sid] = create(merged_appeal_count: merge_count)
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
