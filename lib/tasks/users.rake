# frozen_string_literal: true

namespace :users do
  desc "coerce all user css_id values to UPCASE where possible"
  task upcase: :environment do
    User.all.each do |user|
      css_id = user.css_id
      next if css_id == css_id.upcase

      # look for any duplicates in alternate casings
      matches = User.where("UPPER(css_id)=UPPER(?)", css_id)
      if matches.count > 1
        puts "Cannot upcase #{css_id} because duplicates exist in alternate casings"
        next
      end
      user.update!(css_id: css_id.upcase)
    end
  end

  desc "report on a user db footprint"
  task footprint: :environment do
    css_id = ENV.fetch("CSS_ID")
    reporter = UserReporter.new(css_id)
    reporter.report.each { |ln| puts ln }
  end

  desc "find duplicates and suggest which one(s) to delete"
  task dedupe: :environment do
    users = User.all
    css_ids = users.map(&:css_id).map(&:upcase)
    dupes = css_ids.select { |e| css_ids.count(e) > 1 }.uniq
    dupes.each do |css_id|
      puts "Duplicate: #{css_id}"
      reporter = UserReporter.new(css_id)
      reporter.report.each { |ln| puts ln }
    end
  end

  desc "moves any hearings and hearing days assigned to the lowercase css_id of a user to the uppercase version"
  task dedupe_hearings: :environment do
    users = User.all
    css_ids = users.map(&:css_id)
    dupes = css_ids.
      select { |e| e.upcase != e && css_ids.count(e.upcase) == 1 }.
      map { |e| { old: e, new: e.upcase } }
    output = dupes.map do |css_ids|
      upper_case_user = User.find_by(css_id: css_ids[:new])
      lower_case_user = User.find_by(css_id: css_ids[:old])
      {
        day: HearingDay.where(judge_id: lower_case_user.id).count,
        hearing: Hearing.where(judge_id: lower_case_user.id).count
      }
    end
  end
end
