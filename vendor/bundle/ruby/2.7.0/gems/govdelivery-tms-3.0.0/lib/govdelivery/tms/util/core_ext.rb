require 'active_support/inflector'

module GovDelivery::TMS::CoreExt
  def demodulize(path)
    ActiveSupport::Inflector.demodulize(path)
  end

  def camelize(str)
    # Do not use ActiveSupport::Inflector.camelize because it uses global
    # ActiveSupport::Inflector.acronum data.
    str.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end

  def singularize(str)
    ActiveSupport::Inflector.singularize(str)
  end

  def pluralize(str)
    ActiveSupport::Inflector.pluralize(str)
  end

  def tmsify(klassname)
    ActiveSupport::Inflector.underscore(demodulize(klassname))
  end

  def instance_class(klass)
    ActiveSupport::Inflector.constantize(singularize(klass.to_s))
  end
end
