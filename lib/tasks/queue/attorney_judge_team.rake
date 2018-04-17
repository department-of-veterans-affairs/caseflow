require "csv"

namespace :queue do
  namespace :attorney_judge_team do
    desc "Generate attorney judge team list"
    task generate: [:environment] do
      CHIEFS = ["Bob Scharnberger", "Anthony Scire", "Cherry Crawford",
                "Cynthia Bruce", "John Jones", "Keith Allen", "Theresa Catino"].freeze
      result = {}
      not_found = []
      CSV.foreach(Rails.root.join("lib", "tasks", "queue", "files", "attorneys_judges_chiefs.csv")) do |row|
        next unless CHIEFS.include?(row.first.strip)
        puts "Generating for judge: #{row.second.strip} and attorney: #{row.third.strip}"

        judge_css_id = UserRepository.css_id_by_full_name(row.second.strip)
        attorney_css_id = UserRepository.css_id_by_full_name(row.third.strip)

        if judge_css_id.nil? || attorney_css_id.nil?
          not_found << row.second.strip unless judge_css_id
          not_found << row.third.strip unless attorney_css_id
          next
        end

        result[judge_css_id] ||= {}
        result[judge_css_id][:judge_name] ||= row.second.strip
        result[judge_css_id][:attorneys] ||= []
        result[judge_css_id][:attorneys] << { name: row.third.strip,
                                              css_id: attorney_css_id }
      end
      puts result.inspect
    end
  end
end
