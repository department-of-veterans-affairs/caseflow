class AppealSeries < ActiveRecord::Base
  has_many :appeals

  attr_accessor :incomplete
  attr_accessor :merged_appeal_count

  class << self
    def appeal_series_by_vbms_id(vbms_id)
      appeals = Appeal.repository.appeals_by_vbms_id(vbms_id)

      return [] if appeals.empty?

      no_series_cnt = appeals.count { |appeal| !appeal.appeal_series }
      needs_update = no_series_cnt > 0

      if !needs_update
        merge_cnt = appeals.count { |appeal| appeal.disposition == "Merged Appeal" }
        needs_update = merge_cnt != appeals.first.appeal_series.merged_appeal_count
      end

      generate_appeal_series_for_vbms_id(vbms_id) if needs_update

      appeals.map(&:appeal_series).uniq
    end

    private

    def generate_appeal_series_for_vbms_id(vbms_id)
      appeals = Appeal.repository.appeals_by_vbms_id(vbms_id)

      appeals.map(&:appeal_series).compact.uniq.each(&:delete)

      nodes = appeals.map do |appeal|
        node = { appeal: appeal, children: [] }
        next node if appeal.type == "Original"

        if %w(B W).include? appeal.id[-1]
          parent_id = appeal.id[0...-1]
          parent_candidates = appeals.select { |candidate| candidate.id == parent_id }

          if parent_candidates.length == 1
            node[:parent_appeal] = parent_candidates.first
          else
            node[:incomplete] = true
          end

          next node
        end

        if !appeal.prior_decision_date || appeal.prior_decision_date >= appeal.decision_date
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

      roots, children = nodes.partition { |node| !node[:parent_appeal] }

      children.each do |child|
        parent = nodes.select { |node| node[:appeal] == child[:parent_appeal] }.first
        parent[:children].push(child)
        child.delete(:parent_appeal)
      end

      merge_table = {}
      series_table = {}

      traverse = lambda do |node, &block|
        block.call(node)
        node[:children].each { |child| traverse.call(child, block) }
      end

      roots.each_with_index do |root, sid|
        traverse.call(root) do |node|
          node[:series_id] = sid
        end

        merge_table[sid] = sid
      end

      merged = nodes.select { |node| node[:appeal].disposition == "Merged Appeal" }

      merge_cnt = merged.length

      merged.each do |node|
        date = node[:appeal].decision_date.strftime("%m/%d/%y")
        folder = node[:appeal].id
        merge_str = "From appeal merged on #{date} (#{folder})"

        destination_candidates = nodes.select do |candidate|
          candidate[:appeal].issues.any? do |issue|
            issue.description.include?(merge_str)
          end
        end

        if destination_candidates.length == 1
          merge_table[node[:series_id]] = destination_candidates.first[:series_id]
        end
      end

      merge_table.values.uniq.each do |sid|
        series_table[sid] = create(merged_appeal_count: merge_cnt)
      end

      nodes.each do |node|
        node[:appeal].appeal_series = series_table[merge_table[node[:series_id]]]
        node[:appeal].appeal_series.incomplete = true if node[:incomplete]
      end
    end
  end
end
