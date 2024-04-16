def perform
  webex_service = ExternalApi::WebexService.new(host: ENV['WEBEX_HOST'], port: ENV['WEBEX_PORT'], aud: ENV['WEBEX_AUD'], apikey: ENV['WEBEX_API_KEY'], domain: ENV['WEBEX_DOMAIN'], api_endpoint: ENV['WEBEX_API_ENDPOINT'])
  response = webex_service.refresh_access_token

  if response.present?
    new_access_token = response['access_token']
    new_refresh_token = response['refresh_token']

    credstash = Rcredstash::Client.new
    credstash.put('webex_access_token', new_access_token, context: {}, version: 1)
    credstash.put('webex_refresh_token', new_refresh_token, context: {}, version: 1)

    # Delete old versions of the secrets
    dynamodb = Aws::DynamoDB::Client.new
    dynamodb.scan(table_name: 'appeals-rotating-tokens').items.each do |item|
      if item['name'] == 'webex_access_token' || item['name'] == 'webex_refresh_token'
        if item['version'] != '0000000000000000001'
          dynamodb.delete_item(table_name: 'appeals-rotating-tokens', key: { 'name' => item['name'], 'version' => item['version'] })
        end
      end
    end
  else
    # Retry logic here
  end
rescue StandardError => e
  log_error(e)
ensure
  # Schedule the job to run again in 24 hours
  self.class.set(wait: 24.hours).perform_later
end
