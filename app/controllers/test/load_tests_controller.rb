# frozen_string_literal: true

class Test::LoadTestsController < ApplicationController
  include ProdtestOnlyConcern
  skip_before_action :verify_authentication, only: [:build_cookie]

  LOAD_TESTING_USER = "LOAD_TESTER"

  def index
    render template: "test/index"
  end

  def build_cookie
    save_session(load_test_user)
    render template: "test/index"
  end

  # Desciption: Method to generate request to Jenkins to run the load tests
  #
  # Params: data- A JSON object containing all the data in the Load Test
  #               configuration form
  #
  # Returns: Renders a JSON object with a "201" if the request successfully
  #          kicks off the Jenkins pipeline
  def run_load_tests
    # Set up Jenkins crumbIssuer URI
    crumb_issuer_uri = URI(ENV["JENKINS_CRUMB_ISSUER_URI"])
    crumb_issuer_uri.query = URI.encode_www_form({ token: ENV["LOAD_TESTING_PIPELINE_TOKEN"] })
    http = Net::HTTP.new(crumb_issuer_uri.host, crumb_issuer_uri.port)

    # Create GET request to crumbIssuer and get back response containing the crumb
    crumb_request = Net::HTTP::Get.new(crumb_issuer_uri.request_uri)
    crumb_response = http.request(crumb_request)

    # If the crumbIssuer response is successful, send the Jenkins request to kick off the pipeline
    if crumb_response.is_a?(Net::HTTPOK)
      request_headers = generate_request_headers(crumb_response)
      encoded_test_recipe = encode_test_recipe(request.body.string)

      jenkins_response = send_jenkins_run_request(request_headers, encoded_test_recipe)
    else
      fail StandardError, "Crumb Response: #{crumb_response.body}"
    end

    render json: {
      load_test_run: "#{jenkins_response.code} #{jenkins_response.body}"
    }
  rescue StandardError => error
    render json: {
      error: error
    }
  end

  private

  def load_test_user
    User.find_or_initialize_by(css_id: LOAD_TESTING_USER)
  end

  # Private: Method to save the current_user's session cookie
  # Params: user
  # Response: None
  def save_session(user)
    session[:user] = user.to_session_hash
    session[:regional_office] = user.selected_regional_office
  end

  # Private: Generates headers for request to Jenkins to kick off load test pipeline
  def generate_request_headers(crumb_response)
    crumb_body = JSON.parse(crumb_response.body)
    { "content-type" => "application/x-www-form-urlencoded",
      crumb_body["crumbRequestField"] => crumb_body["crumb"],
      "Cookie" => parse_cookie_from_crumb(crumb_response) }
  end

  # Private: Parse cookie from the Jenkins crumbIssuer API response
  def parse_cookie_from_crumb(crumb_response)
    crumb_response.to_hash["set-cookie"][0].split('\;')[0]
  end

  # Private: Base64 encode the test_recipe to be passed as a parameter
  #  to kick off the load test pipeline in Jenkins
  def encode_test_recipe(test_recipe)
    Base64.encode64(test_recipe)
  end

  # Private: Create a request to kick off the load test pipeline in Jenkins.
  # Sends the request and raises an error if there are any failures
  def send_jenkins_run_request(request_headers, encoded_test_recipe)
    # Set up Jenkins pipeline URI with parameters
    jenkins_pipeline_uri = URI(ENV["LOAD_TESTING_PIPELINE_URI"])
    jenkins_pipeline_uri.query = URI.encode_www_form({ token: ENV["LOAD_TESTING_PIPELINE_TOKEN"] })
    http = Net::HTTP.new(jenkins_pipeline_uri.host, jenkins_pipeline_uri.port)

    # Create POST request to Jenkins pipeline
    jenkins_run_request = Net::HTTP::Post.new(jenkins_pipeline_uri, request_headers)
    encoded_form = URI.encode_www_form({ testRecipe: encoded_test_recipe })
    jenkins_run_request.body = encoded_form
    jenkins_response = http.request(jenkins_run_request)

    # Raise error if the pipeline run is not created
    unless jenkins_response.is_a?(Net::HTTPCreated)
      fail StandardError, "Jenkins Response: #{jenkins_response.body}"
    end

    jenkins_response
  end
end
