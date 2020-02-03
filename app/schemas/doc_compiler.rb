# frozen_string_literal: true

# DocCompiler traverses a schema AST to generate per-field documentation, using the
# visitor pattern adapted from dry-schema's sample code:
# https://dry-rb.org/gems/dry-schema/1.4/advanced/rule-ast/
# Though maintenance of this code should be infrequent, it requires an understanding of
# the relationship between AST form and declarative form. Hopefully dry-schema will one
# day provide a declarative representation and render this unnecessary.
class DocCompiler
  def visit(node)
    meth, rest = node
    public_send(:"visit_#{meth}", rest)
  end

  def visit_set(nodes)
    nodes.flat_map do |node|
      visit(node).map { |key, value| value.merge(name: key) }
    end
  end

  def visit_and(node)
    left, right = node
    visit(left).merge(visit(right)) { |key, one, two| one.merge(two) }
  end

  def visit_key(node)
    name, rest = node
    validations = visit(rest).map { |name, args| predicate_description(name, args) }
    { name => validations.reduce(&:merge) }
  end

  def visit_implication(node)
    _, right = node.map(&method(:visit))
    right.values.first[:optional] = true
    right
  end

  def visit_predicate(node)
    name, args = node
    return {args[0][1] => {required: true}} if name.equal?(:key?)

    { name => args.map(&:last).reject { |v| v.equal?(Dry::Schema::Undefined) }.reduce(&:merge) }
  end

  def predicate_description(name, args)
    case name
    when :filled? then {filled: true}
    when :str? then {type: "string"}
    when :int? then {type: "integer"}
    when :bool? then {type: "boolean"}
    when :date? then {type: "date"}
    when :included_in? then {type: "enum", values: args}
    when :gt? then {greater_than: args[0]}
    else
      raise NotImplementedError, "#{name} not supported yet"
    end
  end
end
