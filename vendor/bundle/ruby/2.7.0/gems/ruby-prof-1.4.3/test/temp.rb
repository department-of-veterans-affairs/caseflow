require 'redis'

path = File.expand_path(File.join(__dir__, '..', 'lib'))
$LOAD_PATH << path
require 'ruby-prof'

Widget = Struct.new(:key) do
  def set!
    Redis.current.set(key, 1, ex: 10)
  end
end

result = RubyProf.profile do
  (1..20).each { |i| Widget.new(i).set! }
end

printer = RubyProf::CallStackPrinter.new(result)
File.open("framez.html", 'w:ASCII-8BIT') do |file|
  printer.print(file, {})
end