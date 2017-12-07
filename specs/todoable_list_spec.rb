require './lib/todoable_list'
require 'rspec'
require 'webmock/rspec'
require 'securerandom'

RSpec.describe TodoableList do

  # in a production test we would have a test user and we would not store this info in a publicly accessible file
  TEST_USER = 'andy.kriger@gmail.com'.freeze
  TEST_PASS = 'todoable'.freeze

  # my preference is to allow real connections when testing
  # mocks have a tendency to stray from reality or never represent reality accurately to begin with
  # that said, mocks have their place and there's usually a good discussion to be had around when to use them
  before(:all) { WebMock.allow_net_connect! }

  # this will take some time but we want to clean up
  after(:all) do
    client = TodoableClient.new TEST_USER, TEST_PASS
    all_lists = TodoableList.all client: client
    puts "\n\ncleaning up...deleting #{all_lists.length} QA lists"
    all_lists.find_all { |l| l.name =~ /^QA/ }.map(&:delete)
  end

  let(:user) { TEST_USER }
  let(:pass) { TEST_PASS }
  let(:client) { TodoableClient.new user, pass }
  let(:listname) { generate_listname }
  let(:new_list) { TodoableList.new name: listname, client: client }

  it 'should retrieve all lists' do
    lists = TodoableList.all user: 'andy.kriger@gmail.com', pass: 'todoable'
    expect(lists).to_not be_nil
    expect(lists.map(&:name)).to_not be_empty
  end

  describe 'list creation' do
    it 'should create a list' do
      expect(new_list).to_not be_nil
      expect(new_list.name).to eq listname
      expect(new_list.id).to_not be_nil
    end

    it 'should not create a list with a duplicate name' do
      list = TodoableList.new name: listname, client: client
      expect(list.name).to eq listname
      expect { TodoableList.new name: listname, client: client }.to raise_error StandardError, /has already been taken/
    end

    it 'should have limits on the list name', skip: 'current behavior allows extremely long names' do
      listname += 'x' * 1_000_000 # apparently not - hmmmmm
      list = TodoableList.new name: listname, client: client
      expect(list['name']).to eq listname # i would have expected a validation failure here
    end

    # this is not the way the system currently works
    # however, it is a reasaonable expecation that a new list would have no items
    it 'a new list should have no items', skip: 'current behavior is to seed a list with random items' do
      expect(new_list).to_not be_nil
      retreived_list = TodoableList.by_id new_list.id
      expect(retreived_list).to_not be_nil
      expect(retreived_list.items).to be_empty
    end
  end

  describe 'list retrieval' do
    it 'should retrieve a list' do
      expect(new_list).to_not be_nil
      retreived_list = TodoableList.by_id new_list.id, client: client
      expect(retreived_list).to_not be_nil
      expect(retreived_list.name).to eq retreived_list.name
      # validate that only one auth request was needed
      expect(WebMock).to have_requested(:post, TodoableClient::BASE_URL + 'authenticate').once
    end

    it 'should raise a exception for a non-existent list' do
      expect { TodoableList.by_id generate_listname, client: client }.to raise_error ArgumentError, 'not found'
    end
  end

  describe 'list updating' do
    it 'should update the name of a list' do
      expect(new_list).to_not be_nil
      new_name = generate_listname
      result = new_list.update new_name
      expect(result).to eq true
      expect(new_list.name).to eq new_name
      retrieved_list = TodoableList.by_id new_list.id, client: client
      expect(retrieved_list.name).to eq new_name
    end
  end

  describe 'list deletion' do
    it 'should delete a list' do
      expect(new_list).to_not be_nil
      result = new_list.delete
      expect(result).to eq true
      expect { TodoableList.by_id new_list.id, client: client }.to raise_error ArgumentError, 'not found'
    end

    it 'should delete an already deleted list' do
      expect(new_list).to_not be_nil
      new_list.delete
      expect { new_list.delete }.to raise_error ArgumentError, 'not found'
    end
  end

  describe 'list items' do
    it 'a listed object lazily loads items' do
      all_lists = TodoableList.all client: client
      list = all_lists.first
      expect(list.items_loaded?).to eq false
      list.items
      expect(list.items).to be_an Array
      # validate that we are not being lazy and always requesting items
      expect(WebMock).to have_requested(:get, TodoableClient::BASE_URL + "lists/#{list.id}").twice
    end

    it 'a newly created list does not return its items' do
      expect(new_list.items_loaded?).to eq false
    end

    it 'can add an item' do
      itemname = generate_listname
      response = new_list.add_item itemname
      expect(response).to be_a TodoableItem
      expect(response.name).to eq itemname
      items = new_list.items
      expect(items.map(&:name)).to include itemname
    end

    it 'can add multiple items with the same name' do
      itemname = generate_listname
      item1 = new_list.add_item itemname
      expect(item1).to be_a TodoableItem
      item2 = new_list.add_item itemname
      expect(item2).to be_a TodoableItem
      expect(item1.id).to_not eq item2.id
    end

    it 'can delete an item' do
      itemname = generate_listname
      item = new_list.add_item itemname
      expect(item).to_not be_nil
      item.delete
      expect(new_list.items.map(&:name)).to_not include itemname
    end

    it 'raises an error when deleting an item again' do
      itemname = generate_listname
      item = new_list.add_item itemname
      expect(item).to_not be_nil
      item.delete
      expect { item.delete }.to raise_error StandardError
    end

    it 'can finish an item' do
      itemname = generate_listname
      item = new_list.add_item itemname
      expect(item).to_not be_nil
      expect(item.finished_at).to be_nil
      item.finish
      all_items = new_list.items
      expect(all_items.find { |i| i.name == itemname }.finished_at).to_not be_nil
    end
  end

  def generate_listname
    "QA#{SecureRandom.uuid}"
  end
end