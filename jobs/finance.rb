require 'net/http'
require 'json'
require 'uri'

quote = "HO.PA" # Thales

SCHEDULER.every '5m', allow_overlapping: false do
  uri = URI.parse("https://finance.yahoo.com/quote/#{quote}?p=#{quote}&.tsrc=fin-srch")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  data = /root\.App\.main = {.*\n/.match(response.body)[0][16..-3] # Remove \n, ;, and prefix
  json_response = JSON.parse(data)
  dict = json_response["context"]["dispatcher"]["stores"]["StreamDataStore"]["quoteData"][quote]
  long_name = dict["longName"]
  change = dict["regularMarketChange"]["fmt"]
  price = dict["regularMarketPrice"]["fmt"]
  send_event('finance', {quote, long_name, change, price})
end
