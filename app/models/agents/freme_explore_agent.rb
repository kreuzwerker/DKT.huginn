module Agents
  class FremeExploreAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `FremeExploreAgent` can retrieve description of a resource from a given endpoint. The endpoint can be SPARQL or Linked Data Fragments endpoint.

      The Agent accepts all configuration options of the `/e-link/explore` endpoint as of version `0.5`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.5/api-doc/simple.html#!/e-Link/explore) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere, make sure to include the API version.

      `outformat` requested RDF serialization format of the output

      `resource` a URI of the resource which should be described.

      `endpoint` a URL of the endpoint which should be used to retrieve info about the resource.

      `endpoint_type` the type of the endpoint
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.5/',
        'outformat' => 'turtle',
        'endpoint' => '',
        'resource' => '',
        'endpoint_type' => 'sparql'
      }
    end

    form_configurable :base_url
    form_configurable :outformat, type: :array, values: ['json-ld', 'turtle', 'n3', 'n-triples', 'rdf-xml']
    form_configurable :resource
    form_configurable :endpoint
    form_configurable :endpoint_type, type: :array, values: ['sparql', 'ldf']

    def validate_options
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "resource needs to be present") if options['resource'].blank?
      errors.add(:base, "endpoint needs to be present") if options['endpoint'].blank?
      validate_web_request_options!
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'resource', 'endpoint', 'endpoint_type'], URI.join(mo['base_url'], 'e-link/explore'))
      end
    end
  end
end
