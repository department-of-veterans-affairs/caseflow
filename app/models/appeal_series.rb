class AppealSeries < ActiveRecord::Base
  has_many :appeals

  attr_accessor :incomplete

  def self.appeal_series_by_vbms_id(vbms_id)
    appeals = AppealRepository.appeals_by_vbms_id(vbms_id)

    no_series_cnt = appeals.reduce(0) { |cnt, appeal | cnt += 1 unless appeal.appeal_series }
    generate_appeal_series_from_appeals(vbms_id) unless no_series_cnt == 0

    appeals.map(&:appeal_series).uniq
  end

  private

  def self.generate_appeal_series_for_vbms_id(vbms_id)
    appeals = AppealRepository.appeals_by_vbms_id(vbms_id)

    appeals.map(&:appeal_series).uniq.each { |series| series.delete }

    nodes = appeals.map do |appeal|
      node = { :appeal => appeal, :children => [] }
      return node if appeal.type == "Original"

      if ["B", "W"].include? appeal.id[-1] then
        parent_id = appeal.id[0...-1]
        parent_candidates = appeals.select { |candidate| candidate.id == parent_id }

        if parent_candidates.length == 1 then
          node[:parent_appeal] = parent_candidates.first
        else
          node[:incomplete] = true
        end

        return node
      end

      if !appeal.prior_decision_date || appeal.prior_decision_date >= appeal.decision_date then
        node[:incomplete = true]
        return node
      end

      parent_candidates = appeals.select do |candidate|
        candidate.decision_date == appeal.prior_decision_date
      end

      if parent_candidates.length == 0 then
        node[:incomplete] = true
        return node
      elsif parent_candidates.length == 1 then
        node[:parent_appeal] = parent_candidates.first
        return node
      end

      parent_candidates.select! do |candidate|
        (appeal.issue_codes & candidate.issue_codes).length > 0
      end

      if (parent_candidates.length == 1) then
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

    def traverse(node, &block) do
      yield(node)
      node.children.each { |child| traverse(child, block) }
    end

    merge_table = {}
    series_table = {}

    roots.each_with_index do |root, sid|
      traverse(node) do |node|
        node[:series_id] = sid
      end

      merge_table[sid] = sid
    end

    nodes.select { |node| node[:appeal].disposition == "Merged Appeal" }
      .each do |node|
        date = node[:appeal].decision_date.strftime('%m/%d/%y')
        folder = node[:appeal].id
        merge_str = "From appeal merged on #{date} (#{folder})"

        destination_candidates = nodes.select do |candidate|
          candidate[:appeal].issues.any? do |issue|
            issue.description.include?(merge_str)
          end
        end

        if destination_candidates.length == 1 then
          merge_table[node[:series_id]] = destination_candidates.first[:series_id]
        end
      end

    merge_table.values.uniq.each do |sid|
      series_table[sid] = self.create
    end

    nodes.each do |node|
      node[:appeal].appeal_series = series_table[merge_table[node[:series_id]]]
      node[:appeal].appeal_series.incomplete = true if node[:incomplete]
    end
  end
end
