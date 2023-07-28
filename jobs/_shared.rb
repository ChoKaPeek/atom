require 'json'
require 'net/http'
require 'uri'

def dump(data)
  puts data.inspect
end

def fetch_data(path, headers = {})
  response = Net::HTTP.get_response(URI(path), headers)
  puts path
  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end

def post_data(path, params = {})
  response = Net::HTTP.post_form(URI(path), params, headers)
  puts path
  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end

def post_data(path, params, headers)
  # URL for the POST request
  url = URI(path)
  puts path

  # Create a new Net::HTTP::Post request
  request = Net::HTTP::Post.new(url.path)

  # Set the headers for the request
  headers.each do |header, value|
    request.add_field(header, value)
  end

  # Encode the data in the format expected by Net::HTTP.post_form
  request.set_form_data(params)

  # Make the request and get the response
  response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
    http.request(request)
  end

  if response.code != '200'
    raise response.body
  end
  return JSON.parse(response.body)
end
