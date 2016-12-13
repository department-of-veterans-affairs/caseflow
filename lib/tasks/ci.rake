require "rainbow"
require "rspec"

task default: "ci:all"

namespace :ci do
  desc "Runs all the continuous integration scripts"
  task all: [:lint, :security, :spec, :sauceci, "konacha:run", :mocha]

  desc "run ruby rspec tests"
  task rspec: [:spec]

  desc "run remaining non-rspec continuous integration scripts"
  task "all-other" => [:lint, :security, :sauceci, "konacha:run", :mocha]
end
