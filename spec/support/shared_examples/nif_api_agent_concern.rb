require 'rails_helper'

shared_examples_for NifApiAgentConcern do
  it "event description does not throw an exception" do
    expect(@checker.event_description).to include('body')
  end

  context '#working' do
    it 'is not working without having received an event' do
      expect(@checker).not_to be_working
    end

    it 'is working after receiving an event without error' do
      @checker.last_receive_at = Time.now
      expect(@checker).to be_working
    end
  end

  it "check calls receive with an empty event" do
    event = Event.new
    mock(Event).new { event }
    mock(@checker).receive([event])
    @checker.check
  end

  it "nif_request! does use the auth_token from provided agent options" do
    stub_request(:post, "http://nif/").
      with(:headers => {'X-Auth-Token'=>'AUTH', 'Accept-Encoding'=>'gzip,deflate', 'Content-Length'=>'0', 'Content-Type'=>'', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
      to_return(:status => 200, :body => "", :headers => {})
    @checker.send(:nif_request!, {'auth_token' => 'AUTH'}, [], '/nif')
  end
end
