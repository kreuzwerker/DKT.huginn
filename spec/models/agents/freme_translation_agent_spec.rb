require 'rails_helper'

describe Agents::FremeTranslationAgent do
  before(:each) do
    @valid_options = Agents::FremeTranslationAgent.new.default_options
    @checker = Agents::FremeTranslationAgent.new(:name => "somename", :options => @valid_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it_behaves_like WebRequestConcern
  it_behaves_like NifApiAgentConcern

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "requires body to be present" do
      @checker.options['body'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires base_url to be set" do
      @checker.options['base_url'] = ''
      expect(@checker).not_to be_valid
    end

    it "requires base_url to end with a slash" do
      @checker.options['base_url']= 'http://example.com'
      expect(@checker).not_to be_valid
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://api.freme-project.eu/0.5/e-terminology/tilde?outformat=turtle&source-lang=en&target-lang=de").
        with(:body => "Hello from Huginn",
             :headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
        to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end
  end
end
