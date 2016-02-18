desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, "konacha:run"]

task default: :ci
