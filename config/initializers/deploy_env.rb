module Rails
  class EnvironmentNotFound < StandardError; end

  def self.deploy_env?(environment)
    deploy_env = {
      "uat"     => :uat,
      "preprod" => :preprod,
      "prod"    => :prod
    }[ENV["DEPLOY_ENV"]] || :demo

    deploy_env == environment
  end
end