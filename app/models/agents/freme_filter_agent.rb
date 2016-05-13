module Agents
  class FremeFilterAgent < Agent
    include FormConfigurable
    include WebRequestConcern
    include NifApiAgentConcern

    default_schedule 'never'

    description <<-MD
      The `FremeFilterAgent` allows to execute a certain filter against a RDF graph sent as post body or as value of the NIF input parameter. For more information and a list of available filters, see the [Simply FREME output using SPARQL filters](http://api.freme-project.eu/doc/0.5/knowledge-base/filtering.html) article.

      The Agent accepts all configuration options of the `/toolbox/filter/documents` endpoint as of version `0.5`, have a look at the [offical documentation](http://api.freme-project.eu/doc/0.5/api-doc/full.html#!/Postprocessing/post_toolbox_filter_documents_name) if you need additional information.

      All Agent configuration options are interpolated using [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) in the context of the received event.

      `base_url` allows to customize the API server when hosting the FREME services elswhere, make sure to include the API version.

      `body` use [Liquid](https://github.com/cantino/huginn/wiki/Formatting-Events-using-Liquid) templating to specify the data to be send to the API.

      `body_format` specify the content-type of the data in `body`

      `outformat` requested RDF serialization format of the output

      `name` name of filter to execute against, [the official documentation](http://api.freme-project.eu/doc/0.5/api-doc/full.html#!/Postprocessing/get_toolbox_filter_manage) has a list of all available filters.
    MD

    def default_options
      {
        'base_url' => 'http://api.freme-project.eu/0.5/',
        'body' => '{{ body }}',
        'body_format' => 'text/plain',
        'outformat' => 'turtle',
        'name' => '',
      }
    end

    form_configurable :base_url
    form_configurable :body
    form_configurable :body_format, type: :array, values: ['text/n3', 'text/turtle', 'application/ld+json', 'application/n-triples', 'application/rdf+xml']
    form_configurable :outformat, type: :array, values: ['csv', 'xml', 'json', 'json-ld', 'turtle', 'n3', 'n-triples', 'rdf-xml']
    form_configurable :name, roles: :completable

    def validate_options
      errors.add(:base, "body needs to be present") if options['body'].blank?
      errors.add(:base, "base_url needs to be present") if options['base_url'].blank?
      errors.add(:base, "base_url needs to end with a trailing '/'") unless options['base_url'].end_with?('/')
      errors.add(:base, "name needs to be present") if options['name'].blank?
      validate_web_request_options!
    end

    def complete_name
      response = faraday.run_request(:get, URI.join(interpolated['base_url'], 'toolbox/filter/manage'), nil, { 'Accept' => 'application/json'})
      return [] if response.status != 200

      JSON.parse(response.body).map { |filter| { text: "#{filter['name']}", id: filter['name'] } }
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        mo = interpolated(event)

        nif_request!(mo, ['outformat', 'name'], URI.join(mo['base_url'], 'toolbox/filter/documents/', mo['name']))
      end
    end
  end
end
