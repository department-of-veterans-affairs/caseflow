namespace :users do
  desc "find duplicates and suggest which one(s) to delete"
  task dedupe: :environment do
    users = User.all
    css_ids = users.map(&:css_id)
    dupes = css_ids.select { |e| css_ids.count(e) > 1 }.uniq
    dupes.each do |css_id|
      puts "Duplicate: #{css_id}"
      users = User.where(css_id: css_id)
      users.each do |user|
        stats = Intake.user_stats(user)
        [
          AdvanceOnDocketMotion,
          Annotation,
          AppealView,
          Certification,
          Dispatch::Task,
          EndProductEstablishment,
          RampElectionRollback,
          SchedulePeriod
        ].each do |cls|
          num = cls.where(user_id: user.id).count
          if num > 0
            puts "#{user.id} has #{num} #{cls}"
          end
        end
        if stats.empty?
          puts "#{user.inspect} has zero intake stats and may be a candidate to merge/delete"
        end
      end
    end
  end
end
