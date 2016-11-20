require "rainbow"

desc "Runs the continuous integration scripts"
task ci: [:lint, :security, :spec, :sauceci, "konacha:run", :mocha]

task default: :ci

task :mocha do
  mocha_result = ShellCommand.run("npm test", chdir: './client')

  if mocha_result
    puts Rainbow("Passed. All frontend react tests look good").green
  else
    puts Rainbow("Failed. Please check the mocha tests in client/test").red
  end
end
