namespace :users do
  desc "coerce all user css_id values to UPCASE where possible"
  task upcase: :environment do
    User.all.each do |user|
      css_id = user.css_id
      next if css_id == css_id.upcase

      # look for any duplicates in alternate casings
      matches = all_users_for_css_id(css_id)
      if matches.count > 1
        puts "Cannot upcase #{css_id} because duplicates exist in alternate casings"
        next
      end
      user.update!(css_id: css_id.upcase)
    end
  end

  def models_with_user_id
    @models_with_user_id ||= ActiveRecord::Base.descendants.reject(&:abstract_class?)
      .select { |c| c.attribute_names.include?("user_id") }
  end

  def report_user_related_records(user)
    has_related_records = false
    models_with_user_id.each do |cls|
      num = cls.where(user_id: user.id).count
      if num > 0
        puts "#{user.id} has #{num} #{cls}"
        has_related_records = true
      end
    end
    unless has_related_records
      puts "#{user.inspect} has zero related records and may be a candidate to merge/delete"
    end
    has_related_records
  end

  def all_users_for_css_id(css_id)
    User.where("UPPER(css_id)=UPPER(?)", css_id)
  end

  desc "report on a user db footprint"
  task footprint: :environment do
    user_id = ENV.fetch("USER_ID")
    user = User.find user_id
    puts "User #{user_id} -> #{user.inspect}"
    all_users_for_css_id(user.css_id).each do |u|
      report_user_related_records(u)
    end
  end

  desc "find duplicates and suggest which one(s) to delete"
  task dedupe: :environment do
    users = User.all
    css_ids = users.map(&:css_id).map(&:upcase)
    dupes = css_ids.select { |e| css_ids.count(e) > 1 }.uniq
    dupes.each do |css_id|
      puts "Duplicate: #{css_id}"
      all_users_for_css_id(css_id).each do |user|
        report_user_related_records(user)
      end
    end
  end
end
