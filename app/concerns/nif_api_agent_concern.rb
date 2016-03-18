module NifApiAgentConcern
  extend ActiveSupport::Concern

  included do
    can_dry_run!

    event_description <<-MD
      Events look like this:

          {
            "status": 200,
            "headers": {
              "Content-Type": "text/html",
              ...
            },
            "body": "<html>Some data...</html>"
          }
    MD
  end

  def working?
    received_event_without_error?
  end

  def check
    receive([Event.new])
  end

  private

  def nif_request!(mo, configuration_keys, url)
    headers = {
      'Content-Type' => mo['body_format']
    }

    params = {}
    configuration_keys.each do |param|
      params[param.gsub('_', '-')] = mo[param] if mo[param].present?
    end

    response = faraday.run_request(:post, url, mo['body'], headers) do |request|
      request.params.update(params)
    end
    create_event payload: { body: response.body, headers: response.headers, status: response.status }
  end
end