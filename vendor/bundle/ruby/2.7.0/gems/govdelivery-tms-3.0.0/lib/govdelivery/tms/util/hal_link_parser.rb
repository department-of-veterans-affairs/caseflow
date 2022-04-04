module GovDelivery::TMS::Util
  module HalLinkParser
    def parse_links(links)
      @resources = {}
      return if links.nil?
      parse_link(links) && return if links.is_a?(Hash)
      links.each { |link| parse_link(link) }
    end

    def subresources
      @resources
    end

    protected

    def metaclass
      @metaclass ||= class << self
        self
      end
    end

    def parse_link(link)
      link.each do |rel, href|
        if rel == 'self'
          self.href = href
        else
          klass = relation_class(rel)
          klass = self.class if %w(first prev next last).include?(rel)
          if klass
            subresources[rel] = klass.new(client, href)
            setup_subresource(link)
          else
            logger.info("Don't know what to do with link rel '#{rel}' for class #{self.class}!") if self.respond_to?(:logger) && logger
          end

        end
      end
    end

    def relation_class(rel)
      ::GovDelivery::TMS.const_get(camelize(rel)).tap do |klass|
        return nil unless klass.name =~ /GovDelivery::TMS/
      end
    rescue NameError
      nil
    end

    def setup_subresource(link)
      return unless link
      link.each { |rel, _href| metaclass.send(:define_method, rel.to_sym, &lambda { subresources[rel] }) unless rel == 'self' }
    end
  end
end
