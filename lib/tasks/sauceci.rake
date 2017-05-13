desc "convenience task used to run sauce browser tests only on the master travis branch"
task :sauceci do
  sauce_result = true

  if ENV["TRAVIS_BRANCH"] == "master" && !ENV["TRAVIS_PULL_REQUEST"]
    puts "running feature tests on Sauce browsers..."
    sauce_result = ShellCommand.run("rake spec:browsers")
  end

  exit!(1) unless sauce_result
end
