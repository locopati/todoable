require 'todoable_list'

# a representation of an item in the Todoable API
# designed to be responsive to changes in what the API might return
# by using method_missing to create accessors for each key
# here we expect to be using a client from the list so we do not support user/pass
class TodoableItem

  KNOWN_ATTRIBUTES = %i[name finished_at src id].freeze

  # rubocop:disable Lint/AmbiguousOperator
  attr_accessor *KNOWN_ATTRIBUTES

  # initiazlize an item with the data from the server and a client used for future updates
  # @param [Hash] item the data from the server to initialize the item with
  # @param [TodoableClient] client used to delete and finish an item
  def initialize(list, item, client)
    return unless item
    KNOWN_ATTRIBUTES.each do |attr|
      send "#{attr}=", item[attr.to_s]
    end
    @list = list
    @client = client
  end

  def delete
    @client.request :delete, "#{TodoableList::LISTS_PATH}/#{@list.id}/#{TodoableList::ITEMS_PATH}/#{@id}"
  end

  def finish
    @client.request :put, "#{TodoableList::LISTS_PATH}/#{@list.id}/#{TodoableList::ITEMS_PATH}/#{@id}/finish"
  end
end