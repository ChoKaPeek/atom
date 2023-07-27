require 'net/http'
require 'uri'

quote = ENV['QUOTE']

SCHEDULER.every '5m', :first_in => 0 do
  response = Net::HTTP.get_response(URI("https://www.boursorama.com/cours/#{quote}/"))
  long_name = /title="Cours .*"/.match(response.body)[0][13..-1]
  price = /data-ist-last>.*</.match(response.body)[0][14..-1]
  change = /data-ist-variation>.*</.match(response.body)[0][19..-1]
  color = change[0] == "-" ? "negative" : "positive"
  send_event('finance', {quote: quote, long_name: long_name, change: change, price: price, color: color})
end
