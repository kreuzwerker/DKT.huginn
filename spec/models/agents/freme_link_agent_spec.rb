require 'rails_helper'

describe Agents::FremeLinkAgent do
  before(:each) do
    @valid_options = Agents::FremeLinkAgent.new.default_options.merge('templateid' => 'testtemplate')
    @checker = Agents::FremeLinkAgent.new(:name => "somename", :options => @valid_options)
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

    it "requires templateid to be set" do
      @checker.options['templateid'] = ''
      expect(@checker).not_to be_valid
    end
  end

  describe '#complete_templateid' do
    before(:each) do
      faraday_mock = mock()
      @response_mock = mock()
      mock(faraday_mock).run_request(:get, URI.parse('http://api.freme-project.eu/0.5/e-link/templates'), nil, { 'Accept' => 'application/json'}) { @response_mock }
      mock(@checker).faraday { faraday_mock }
    end
    it "returns the available datasets" do
      stub(@response_mock).status { 200 }
      stub(@response_mock).body { JSON.dump([ {'id' => '1245', 'label' => 'label', 'description' => 'description'} ]) }
      expect(@checker.complete_templateid).to eq([{text: "label", id: "1245", description: 'description'}])
    end

    it "returns an empty array if the request failed" do
      stub(@response_mock).status { 500 }
      expect(@checker.complete_templateid).to eq([])
    end
  end

  describe "#receive" do
    before(:each) do
      @event = Event.new(payload: {data: "Hello from Huginn"})
    end

    it "creates an event after a successfull request" do
      stub_request(:post, "http://api.freme-project.eu/0.5/e-link/documents?outformat=turtle&templateid=testtemplate").
         with(:headers => {'Accept-Encoding'=>'gzip,deflate', 'Content-Type'=>'text/plain', 'User-Agent'=>'Huginn - https://github.com/cantino/huginn'}).
         to_return(:status => 200, :body => "DATA", :headers => {})
      expect { @checker.receive([@event]) }.to change(Event, :count).by(1)
      event = Event.last
      expect(event.payload['body']).to eq('DATA')
    end

  end
end
