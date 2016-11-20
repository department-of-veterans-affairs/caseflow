require "rainbow"

desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, :sauceci, "konacha:run", :mocha]

task default: :ci
