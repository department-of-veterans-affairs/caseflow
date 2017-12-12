module RequestHelper
  class << self
    def execute_before_request(&block)
      @before_request = block
    end

    %w(get put post head delete request).each do |method_name|
      define_method(method_name.to_sym) do |*args|
        @before_request.call

        # super(args)
      end
    end
  end

  # include HTTPI
end
