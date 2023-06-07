# frozen_string_literal: true

namespace :db do
  namespace :seed do
    Dir[File.join(Rails.root, "db", "seeds", "*.rb")].each do |filename|
      task_name = File.basename(filename, ".rb").intern

      task task_name => :environment do
        load(filename)
        Seeds::VbmsExtClaim.new.seed!
      end
    end

    task :all => :environment do
      Dir[File.join(Rails.root, "db", "seeds", "*.rb")].sort.each do |filename|
        load(filename)
      end
    end
  end
end
