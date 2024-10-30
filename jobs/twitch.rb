require 'sinatra'
require 'erb'

TWITCH='https://api.twitch.tv/helix'
FOLLOWS=TWITCH+'/streams/followed'

$access_token = ""

SCHEDULER.every '10m' do
  next if $access_token == ""
  send_lives()
end

get '/chokapeek/callback' do
  if params['code']
    data = post_data_form("https://id.twitch.tv/oauth2/token?client_id=#{ENV['TWITCH_CLIENT_ID']}" +
                          "&client_secret=#{ENV['TWITCH_SECRET']}" +
                          "&code=#{params['code']}" +
                          "&grant_type=authorization_code" +
                          "&redirect_uri=#{ERB::Util.url_encode('http://localhost:3030/chokapeek/callback')}"
                         )
    if data['access_token']
      $access_token = data['access_token']
      send_lives()
      redirect '/chokapeek'
    end
  end
end

get '/chokapeek/twitch' do
  redirect "https://id.twitch.tv/oauth2/authorize" +
    "?client_id=#{ENV['TWITCH_CLIENT_ID']}" +
    "&redirect_uri=#{ERB::Util.url_encode('http://localhost:3030/chokapeek/callback')}" +
    "&response_type=code" +
    "&scope=user%3Aread%3Afollows"
end

def fetch_twitch(path)
  headers = {
    'Authorization' => "Bearer #{$access_token}",
    'Client-ID' => ENV['TWITCH_CLIENT_ID'],
  }
  return fetch_data(path, headers)
end

def send_lives()
  user_id = fetch_twitch("#{TWITCH}/users")['data'][0]['id']

  streams = fetch_twitch("#{FOLLOWS}?user_id=#{user_id}&first=100")
  lives = {}
  ids = ""
  streams['data'].each do |stream|
    lives[stream['user_id']] = {
      username: stream['user_name'],
      title: stream['title'],
      since: ((Time.now - Time.parse(stream['started_at'])) / 60).to_i
    }

    ids += "id=" + stream['user_id'] + "&"
  end
  profiles = fetch_twitch("#{TWITCH}/users?#{ids.chop}")
  profiles['data'].each do |profile|
    lives[profile['id']][:profile_picture] = profile['profile_image_url']
  end

  send_event('twitch',
             lives: lives.values)
end
