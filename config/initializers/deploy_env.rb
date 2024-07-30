module Rails
  class EnvironmentNotFound < StandardError; end

  DEPLOY_ENV = {
    "uat"     => :uat,
    "preprod" => :preprod,
    "prodtest" => :prodtest,
    "prod"    => :prod
  }.freeze

  def self.deploy_env?(environment)
    deploy_env = DEPLOY_ENV[ENV["DEPLOY_ENV"]] || :demo

    deploy_env == environment
  end

  def self.current_env
    if Rails.env.to_sym == :production
      ENV["DEPLOY_ENV"].to_sym
    else
      Rails.env.to_sym
    end
  end

  def self.deploy_env
    current_env
  end

  def self.in_upper_env?
    current_env == DEPLOY_ENV["prod"] || current_env == DEPLOY_ENV["prodtest"]
  end
end
