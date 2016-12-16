if ENV["RAILS_ENV"] == "test"
  SimpleCov.start do
    add_filter "lib/fakes"
    add_filter "spec/support"
    add_filter "config/initializers"
    add_filter "lib/tasks"
  end

  SimpleCov.command_name "Test Run" + (ENV["TEST_ENV_NUMBER"] || "")
end

