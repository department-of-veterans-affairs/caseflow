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

  desc "find duplicates and suggest which one(s) to delete"
  task dedupe: :environment do
    users = User.all
    css_ids = users.map(&:css_id).map(&:upcase)
    dupes = css_ids.select { |e| css_ids.count(e) > 1 }.uniq
    dupes.each do |css_id|
      puts "Duplicate: #{css_id}"
      users = User.where("UPPER(css_id)=UPPER(?)", css_id)
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
