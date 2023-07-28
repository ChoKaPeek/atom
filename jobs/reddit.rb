require 'net/http'
require 'json'

placeholder = '/assets/nyantocat.gif'

SCHEDULER.every '1m', first_in: 0 do |job|
  image = placeholder
  json = fetch_data("https://www.reddit.com/#{ENV['SUBREDDIT']}.json", { "User-Agent" => "Atom 0.1" })

  if json['data']['children'].count > 0
    urls = json['data']['children'].map{|child| child['data']['url'] }

    # Ensure we're linking directly to an image, not a gallery etc.
    valid_urls = urls.select{|url| url.downcase.end_with?('png', 'gif', 'jpg', 'jpeg')}
    image = valid_urls.sample(1).first
  end

  send_event('reddit', image: "background-image:url(#{image})")
end
