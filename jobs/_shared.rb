require 'json'
require 'net/http'
require 'uri'

def dump(data)
  puts data.inspect
  $stdout.flush
end

def fetch_data(path, headers = {})
  response = Net::HTTP.get_response(URI(path), headers)
  puts path
  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end

def post_data_form(path)
  response = Net::HTTP.post_form(URI(path), {})
  puts path
  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end

def post_data(path, params, headers)
  puts path
  # URL for the POST request
  url = URI.parse(path)

  headers['Content-Type'] = 'application/json'

  # Create a new Net::HTTP::Post request
  request = Net::HTTP::Post.new(url.request_uri, headers)

  # Add payload
  request.body = params.to_json

  # Make the request and get the response
  response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
    http.request(request)
  end

  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end
