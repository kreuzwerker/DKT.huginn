require 'rails_helper'

describe Agents::ReadabilityAgent do
  before(:each) do
    @checker = Agents::ReadabilityAgent.new(:name => 'somename', :options => Agents::ReadabilityAgent.new.default_options)
    @checker.user = users(:jane)
    @checker.save!
  end

  it 'renders the event description without errors' do
    expect { @checker.event_description }.not_to raise_error
  end

  context '#validate_options' do
    it 'is valid with the default options' do
      expect(@checker).to be_valid
    end

    it 'requires data to be set' do
      @checker.options['data'] = ""
      expect(@checker).not_to be_valid
    end
  end

  context '#receive' do
    let(:event) { Event.new(payload: {'body' => '<html>Hello</html>'}) }
    let(:response_mock) { res = mock(); mock(res).title; mock(res).content; mock(res).author; res }

    it 'calls the readability gem with the default options' do
      mock(Readability::Document).new('<html>Hello</html>', tags: ['div', 'p'], remove_empty_nodes: false) { response_mock }
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      expect(Event.last.payload['body']).to be_nil
    end

    it 'only adds whitelist to the options when it is not blank' do
      @checker.options['whitelist'] = 'html'
      mock(Readability::Document).new('<html>Hello</html>', tags: ['div', 'p'], remove_empty_nodes: false, whitelist: 'html') { response_mock }
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end

    it 'only adds blacklist to the options when it is not blank' do
      @checker.options['blacklist'] = 'html'
      mock(Readability::Document).new('<html>Hello</html>', tags: ['div', 'p'], remove_empty_nodes: false, blacklist: 'html') { response_mock }
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
    end

    it 'does merges the incoming event with the result when merge is set to true' do
      @checker.options['merge'] = 'true'
      mock(Readability::Document).new('<html>Hello</html>', tags: ['div', 'p'], remove_empty_nodes: false) { response_mock }
      expect { @checker.receive([event]) }.to change(Event, :count).by(1)
      expect(Event.last.payload['body']).to eq('<html>Hello</html>')
    end
  end
end
