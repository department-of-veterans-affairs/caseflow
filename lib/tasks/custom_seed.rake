# frozen_string_literal: true

# This allows you to run a custom db:seed file
# for example: bundle exec rake db:seed:custom_seed_file_name
namespace :db do
  namespace :seed do
    Dir[File.join(Rails.root, "db", "seeds", "*.rb")].each do |filename|
      task_name = File.basename(filename, ".rb").intern
      task task_name => :environment do
        load(filename)
        # when bundle exec rake db:seed:vbms_ext_claim is called
        # it runs the seed! method inside vbms_ext_claim.rb
        class_name = task_name.to_s.camelize
        Seeds.const_get(class_name).new.seed!
      end
    end

    task :all => :environment do
      Dir[File.join(Rails.root, "db", "seeds", "*.rb")].sort.each do |filename|
        load(filename)
      end
    end
  end
end
