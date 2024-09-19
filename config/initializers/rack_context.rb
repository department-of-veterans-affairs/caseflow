class RackContextGetter < OpenTelemetry::Context::Propagation::RackEnvGetter

  # :reek:FeatureEnvy
  def get(carrier, key)
    carrier[to_rack_key(key)] || carrier[key]
  end

  protected

  def to_rack_key(key)
    ret = +"HTTP_#{key}"
    ret.tr!('-', '_')
    ret.upcase!
    ret
  end
end

RACK_ENV_GETTER = RackContextGetter.new

OpenTelemetry::Common::Propagation.instance_eval do
  def rack_env_getter
    RACK_ENV_GETTER
  end
end
