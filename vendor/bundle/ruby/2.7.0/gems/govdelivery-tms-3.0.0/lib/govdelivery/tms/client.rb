require 'logger'
# The client class to connect and talk to the TMS REST API.
class GovDelivery::TMS::Client
  include GovDelivery::TMS::Util::HalLinkParser
  include GovDelivery::TMS::CoreExt

  attr_accessor :connection, :href, :api_root, :logger, :sid

  DEFAULTS = { api_root: 'https://tms.govdelivery.com', logger: nil }.freeze

  # Create a new client and issue a request for the available resources for a given account.
  #
  # @param [String] auth_token The auth_token of your account
  # @param [Hash] options
  # @option options [String] :api_root The root URL of the TMS api. Defaults to localhost:3000
  # @option options [Logger] :logger An instance of a Logger class (http transport information will be logged here) - defaults to nil
  #
  # @example
  #   client = TMS::Client.new("auth_token", {
  #                               :api_root => "https://tms.govdelivery.com",
  #                               :logger => Logger.new(STDOUT)})
  #   client = TMS::Client.new("auth_token", {
  #                               api_root: "https://tms.govdelivery.com",
  #                               logger:   false})
  def initialize(auth_token, options = DEFAULTS)
    @api_root = options[:api_root]
    @logger = options.fetch(:logger, setup_logging(options[:debug]))
    connect!(auth_token, options.except(:api_root, :logger, :debug))
    discover!
  end

  def connect!(auth_token, options = {})
    self.connection = GovDelivery::TMS::Connection.new({ auth_token: auth_token, api_root: api_root, logger: logger }.merge!(options))
  end

  def discover!
    services = get('/').body
    self.sid = services['sid']
    parse_links(services['_links'])
  end

  def get(href, params = {})
    response = raw_connection.get(href, params)
    case response.status
    when 500..599
      fail GovDelivery::TMS::Request::Error.new(response.status)
    when 401..499
      fail GovDelivery::TMS::Request::Error.new(response.status)
    when 202
      fail GovDelivery::TMS::Request::InProgress.new(response.body['message'])
    else
      return response
    end
  end

  def post(obj)
    raw_connection.post do |req|
      req.url @api_root + obj.href
      req.headers['Content-Type'] = 'application/json'
      req.body = obj.to_json
    end
  end

  def put(obj)
    raw_connection.put do |req|
      req.url @api_root + obj.href
      req.headers['Content-Type'] = 'application/json'
      req.body = obj.to_json
    end
  end

  def delete(href)
    response = raw_connection.delete(href)
    case response.status
    when 200...299
      return response
    else
      fail GovDelivery::TMS::Request::Error.new(response.status)
    end
  end

  def raw_connection
    connection.connection
  end

  def client
    self
  end

  private

  def setup_logging(debug)
    Logger.new(STDOUT).tap do |logger|
      logger.level = debug ? Logger::DEBUG : Logger::INFO
    end
  end
end
