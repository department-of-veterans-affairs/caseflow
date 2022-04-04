module Akami
  module XPathHelper
    def at_xpath(node, xpath)
      return unless node
      node.at_xpath local_name_xpath(xpath)
    end

    def xpath(node, xpath)
      return unless node
      node.xpath local_name_xpath(xpath)
    end

    def local_name_xpath(xpath)
      xpath.gsub(%r{([/]*)([A-Za-z]+)([/]*)}) { "#{$1}*[local-name()='#{$2}']#{$3}" }
    end
  end
end
