module Rails
  def self.current_env
    if Rails.env.to_sym == :production
      ENV["DEPLOY_ENV"].to_sym
    else
      Rails.env.to_sym
    end
  end
end