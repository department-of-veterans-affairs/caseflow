begin
  require "rspec"

  namespace :spec do
    desc "Run the feature specs with sauce labs on supported browsers"

    RSpec::Core::RakeTask.new(:browsers) do |t|
      ENV["SAUCE_SPECS"] = "true"
      t.pattern = "spec/feature/**/*_spec.rb"
    end
  end

  Rake::Task[:spec].enhance ["assets:clobber"]

  # rubocop:disable Lint/HandleExceptions
rescue LoadError, NameError
end
# rubocop:enable Lint/HandleExceptions
