require 'todoable_client'
require 'todoable_item'

# a client for the Todoable API
# this started as a very literal translation of the API
# then i changed the design to be model-oriented
# there are drawbacks
#   there is a piece of shared state - the client - among the lists and items of a particular user
#   another client could change list state and there's no way to know if the list is out of sync
# the literal translation avoided that by having the client hold the authentication state & always making requests
# in retrospect, I think the literal API was a cleaner solution as it did not require passing the client as often
# also, there's room for clean up if we made it explicit that a client would always be used (rather than supporting user/pass as well)
class TodoableList

  LISTS_PATH = 'lists'.freeze
  ITEMS_PATH = 'items'.freeze

  attr_reader :name, :id

  # either a user/pass pair or a client must be provided
  # either name or list can be provided to initialize the data
  # name will make a request to create a new list
  # @param user [String] the name of the user
  # @param pass [String] the password of the user
  # @param client [TodoableClient] an optional client used to make requests
  # @param name [String] a name for creating a new list
  # @param list [Hash] the values returned from the request
  def initialize(user: nil, pass: nil, client: nil, list: nil, name: nil)
    @client = TodoableList.initialize_client user, pass, client

    list = @client.request :post, LISTS_PATH, list_hash(name) if name

    return unless list
    @id = list['id']
    @name = list['name']
  end

  # @param [String] user retrieve lists for the given user
  # @param [String] pass the password of the given user
  def self.all(user: nil, pass: nil, client: nil)
    client = initialize_client user, pass, client
    response = client.request :get, LISTS_PATH
    raise StandardError, 'lists are missing from the response body' unless response['lists']
    response['lists']&.map { |list| TodoableList.new(client: client, list: list) }
  end

  # either a user/pass pair or a client must be provided
  # @param [String] id the id of the list to retreive
  # @return [Hash] the list and its items
  def self.by_id(id, user: nil, pass: nil, client: nil)
    client = initialize_client user, pass, client
    response = client.request :get, "#{LISTS_PATH}/#{id}"
    TodoableList.new(client: client, list: response)
  end

  # @param [Object] name the new name of the list
  # @return [Boolean] true if updated
  def update(name)
    response = @client.request :patch, "#{LISTS_PATH}/#{@id}", list_hash(name)
    @name = name if response
    response
  end

  # @return [Boolean] true if deleted
  def delete
    @client.request :delete, "#{LISTS_PATH}/#{@id}"
  end

  # items are always loaded from the server to account for the possibility of multiple clients making changes
  # if you create a TodoableList from an id, you will have the items
  # if you requested all lists, you will not have items until you call this
  # @return [Array] a list of TodoableItem
  def items
    response = @client.request :get, "#{LISTS_PATH}/#{@id}"
    raise(StandardError, 'unexpected response') unless response
    response['items']&.map { |i| TodoableItem.new self, i, @client }
  end

  # @param [String] name the name of the new item
  # @return [Boolean] true if created
  def add_item(name)
    response = @client.request :post, "#{LISTS_PATH}/#{@id}/#{ITEMS_PATH}", item: { name: name }
    raise(StandardError, 'unexpected response') unless response
    TodoableItem.new(self, response, @client)
  end

  # primarily for testing that a newly retrieved object has no items
  # @return [Boolean] true if items have been loaded
  def items_loaded?
    !@items.nil?
  end

  # utility method to initialize a client and handle errors consistently
  def self.initialize_client(user, pass, client = nil)
    unless (user && pass) || client
      raise ArgumentError, 'either a user/pass or client must be provided'
    end
    @client = client || TodoableClient.new(user, pass)
  end

  private

  # utility method to generate the parameters for creating/updating a list
  # @param [String] name the name of the list
  def list_hash(name)
    { list: { name: name } }
  end

end