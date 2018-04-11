require "csv"

namespace :queue do
  namespace :attorney_judge_team do
    desc "Generate attorney judge team list"
    task :generate do
      CHIEFS = ["Bob Scharnberger", "Anthony Scire", "Cherry Crawford", "Cynthia Bruce", "John Jones", "Keith Allen", "Theresa Catino"].freeze
      result = {}
      CSV.foreach(Rails.root.join("lib", "tasks", "queue", "files", "attorneys_judges_chiefs.csv")) do |row|
        next unless CHIEFS.include?(row.first.strip)
        puts "Generating for judge: #{row.second.strip}"
        result[row.second.strip] ||= []
        result[row.second.strip] << row.third.strip
      end
      puts result.inspect
    end
  end
end
