require 'net/http'
require 'time'
require 'json'

# centralized HTTP request handling
# if in the future, we want to use a better HTTP gem, we can make a quick change here
# if in the future, the Todoable API authorization or base URL changes, we can easily update here
# to see HTTP logging, call debug(true) on a client instance
class TodoableClient

  BASE_URL = 'http://todoable.teachable.tech/api/'.freeze

  VALID_METHODS = %i[delete get patch post put].freeze

  APP_JSON = 'application/json'.freeze

  AUTH_PATH = 'authenticate'.freeze

  attr_reader :auth_token_expires_at # primarily for testing
  attr_writer :debug

  # initialize the request handler with an authorization token
  # @param [String] user a system user
  # @param [String] pass the user's password
  def initialize(user, pass)
    @user = user
    @pass = pass
    auth_token
  end

  def debug?
    @debug || ENV['HTTP_DEBUG']
  end

  # generic request handler
  # @param [Symbol] method :delete, :get, :patch, :post, or :put
  # @param [String] path the path to the API call
  # @param [Hash] body an optional body for a POST or PUT request
  # @return [Hash] the JSON response converted to a Ruby hash (this could be an OpenStruct if we wanted object-like access)
  # we're okay with the complexity of this method so we can disable the checks - be aware of this when taking this method further
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def request(method, path, body = nil)
    raise ArgumentError, "#{method} is not valid" unless VALID_METHODS.include? method

    request = initialize_request method, path, body

    http = Net::HTTP.new(request.uri.host, request.uri.port)
    http.set_debug_output($stdout) if debug? # we can show our requests here if we need to see what's going on
    http.start do |h|
      response = h.request request
      # this is a place for discussion of how we would want to handle errors
      raise StandardError, 'unexpected response' unless response
      raise ArgumentError, 'unable to authenticate' if response.code == '401'
      raise ArgumentError, 'not found' if response.code == '404' # this could arguably return an empty response
      raise StandardError, JSON.parse(response.body) if response.code == '422' # this could arguably return an empty response
      # TODO: it would be better if finishing an item were consistent in its return value
      if response.code == '200' && path =~ /items.*finish$/ && method == :put
        true
      elsif response.code == '204' && method == :delete
        true
      elsif path =~ /^lists.+$/ && method == :patch
        true
      else
        JSON.parse response.body
      end
    end
  end

  # @return [Hash] the authorization token hash (keys: token & expires_at)
  # retrieves a new one if it does not exist or has expired
  # the token refresh logic has to be validated manually until we can expire tokens via the API
  def auth_token
    if @auth_token && Time.now < @auth_token_expires_at
      @auth_token
    else
      response = request :post, 'authenticate'
      @auth_token_expires_at = Time.parse response['expires_at']
      @auth_token = response['token']
    end
    @auth_token
  end

  private

  # utility method to isolate request object setup
  # @param [Symbol] method :delete, :get, :patch, :post, or :put
  # @param [String] path the path to the API call
  # @param [Hash] body an optional body for a POST or PUT request
  # @return [Net::HTTP::{DELETE, GET, PATCH, POST, PUT}] the request object
  def initialize_request(method, path, body)
    uri = URI.parse(BASE_URL + path)
    method_object = Net::HTTP.const_get method.capitalize

    request = method_object.new uri
    request.basic_auth @user, @pass if path == AUTH_PATH
    # here we need to invoke auth_token rather than use the instance variable
    # otherwise, we will not refresh the token automatically if it has expired
    request['Authorization'] = "Token token=\"#{auth_token}\"" unless path == AUTH_PATH
    request['Accept'] = APP_JSON
    request['Content-Type'] = APP_JSON
    request.body = body.to_json

    request
  end
end
