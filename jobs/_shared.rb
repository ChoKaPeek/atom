require 'json'
require 'net/http'
require 'uri'

def fetch_data(path, headers = {})
  response = Net::HTTP.get_response(URI(path))
  puts path
  raise response.body
  return JSON.parse(response.body)
end

def complex_fetch_data(path)
  url = URI.parse(path)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true if url.scheme == 'https'

  response = http.get(url.request_uri)

  if response.code == '200'
    return JSON.parse(response.body)
  else
    puts "Request failed with status code: #{response.code}"
  end
end
