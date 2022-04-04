module XmlMapper
  class TextNode < Item

    def find(node, namespace, xpath_options)
      if node.children.any? {|c| c.text?}
        yield(node)
      else
        yield(nil)
      end
    end
  end
end
