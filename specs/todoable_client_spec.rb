require './lib/todoable_client'
require 'rspec'
require 'webmock/rspec'

RSpec.describe TodoableClient do

  # in a production test we would have a test user
  subject { TodoableClient.new 'andy.kriger@gmail.com', 'todoable' }

  before(:all) { WebMock.allow_net_connect! }

  it 'should initialize with a token once' do
    first_call = subject.auth_token
    expect(first_call).to_not be_nil
    expect(first_call).to be_a String
    # verify we use the existing token if we have one
    expect(subject.auth_token).to eq first_call
    # verify we only make a single authentication request during initialization
    expect(WebMock).to have_requested(:post, 'todoable.teachable.tech/api/authenticate').once
  end

  it 'should refresh the token automatically', skip: 'cannot implement until the API allows us to expire a token' do
    # ideally the Todoable API would let us expire a token so we could verify we get a new one automatically
  end

  it 'should raise an exception for a non-existent user' do
    expect { TodoableClient.new 'nonexistent-user', 'so it goes' }.to raise_error ArgumentError
  end

end