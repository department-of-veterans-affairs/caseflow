p "EXECUTED .SIMPLECOV"
SimpleCov.start do
  add_filter "lib/fakes"
  add_filter "spec/support"
  add_filter "config/initializers"
  add_filter "lib/tasks"

  SimpleCov.minimum_coverage_by_file 90
end
