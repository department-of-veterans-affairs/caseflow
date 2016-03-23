desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, :sauceci, "konacha:run"]

task default: :ci
