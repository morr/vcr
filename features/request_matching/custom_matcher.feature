Feature: Register and use a custom matcher

  If the built-in matchers do not meet your needs, you can use a custom matcher.

  Any 2-argument callable (that is, an object that responds to #call and accepts
  2 arguments) can be a matcher.  Simply put the callable in your
  `:match_requests_on` array.

  In addition, you can register a named custom matcher with VCR, and use
  the name in your `:match_requests_on` array.

  Either way, your custom matcher should return a truthy value if the
  given requests should be considered equivalent.

  Background:
    Given a previously recorded cassette file "cassettes/example.yml" with:
      """
      --- 
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://foo.com:9000/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "18"
          body: port 9000 response
          http_version: "1.1"
      - !ruby/struct:VCR::HTTPInteraction 
        request: !ruby/struct:VCR::Request 
          method: :get
          uri: http://foo.com:8000/foo
          body: 
          headers: 
        response: !ruby/struct:VCR::Response 
          status: !ruby/struct:VCR::ResponseStatus 
            code: 200
            message: OK
          headers: 
            content-length: 
            - "18"
          body: port 8000 response
          http_version: "1.1"
      """

  Scenario Outline: Use a callable as a custom request matcher
    And a file named "callable_matcher.rb" with:
      """ruby
      include_http_adapter_for("<http_lib>")

      require 'vcr'

      VCR.configure do |c|
        <configuration>
        c.cassette_library_dir = 'cassettes'
      end

      port_matcher = lambda do |request_1, request_2|
        URI(request_1.uri).port == URI(request_2.uri).port
      end

      VCR.use_cassette('example', :match_requests_on => [:method, port_matcher]) do
        puts "Response for port 8000: " + response_body_for(:get, "http://example.com:8000/")
      end

      VCR.use_cassette('example', :match_requests_on => [:method, port_matcher]) do
        puts "Response for port 9000: " + response_body_for(:get, "http://example.com:9000/")
      end
      """
    When I run `ruby callable_matcher.rb`
    Then it should pass with:
      """
      Response for port 8000: port 8000 response
      Response for port 9000: port 9000 response
      """

    Examples:
      | configuration         | http_lib              |
      | c.stub_with :fakeweb  | net/http              |
      | c.stub_with :webmock  | net/http              |
      | c.stub_with :webmock  | httpclient            |
      | c.stub_with :webmock  | curb                  |
      | c.stub_with :webmock  | patron                |
      | c.stub_with :webmock  | em-http-request       |
      | c.stub_with :webmock  | typhoeus              |
      | c.stub_with :typhoeus | typhoeus              |
      | c.stub_with :excon    | excon                 |
      |                       | faraday (w/ net_http) |
      |                       | faraday (w/ typhoeus) |

  Scenario: Register a named custom matcher
    And a file named "register_custom_matcher.rb" with:
      """ruby
      include_http_adapter_for("net/http")

      require 'vcr'

      VCR.configure do |c|
        c.stub_with :fakeweb
        c.cassette_library_dir = 'cassettes'
        c.register_request_matcher :port do |request_1, request_2|
          URI(request_1.uri).port == URI(request_2.uri).port
        end
      end

      VCR.use_cassette('example', :match_requests_on => [:method, :port]) do
        puts "Response for port 8000: " + response_body_for(:get, "http://example.com:8000/")
      end

      VCR.use_cassette('example', :match_requests_on => [:method, :port]) do
        puts "Response for port 9000: " + response_body_for(:get, "http://example.com:9000/")
      end
      """
    When I run `ruby register_custom_matcher.rb`
    Then it should pass with:
      """
      Response for port 8000: port 8000 response
      Response for port 9000: port 9000 response
      """

