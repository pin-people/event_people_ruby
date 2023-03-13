module EventPeople
  class Event
    attr_reader :name, :headers, :body, :schema_version

    def initialize(name, body, schema_version = 1.0)
      @name = name
      @body = body.is_a?(String) ? JSON.parse(body) : body
      @schema_version = @body&.dig('headers', 'schemaVersion') || schema_version

      if name?
        generate_headers
        fix_name
      end

      build_payload if @body&.key?('headers')
    end

    def payload
      { headers: headers, body: body }.to_json
    end

    def body?
      body && !body.empty?
    end

    def name?
      name && !name.empty?
    end

    private

    def build_payload
      @headers = body['headers']
      @body = body['body']
    end

    def generate_headers
      header_spec = name&.split('.')

      @headers = {
        appName: EventPeople::Config::APP_NAME,
        resource: header_spec[0],
        origin: header_spec[1],
        action: header_spec[2],
        destination: header_spec[3] || 'all',
        schemaVersion: schema_version
      }
    end

    def fix_name
      return if name.split('.').size != 3

      @name = "#{@name}.all"
    end
  end
end
