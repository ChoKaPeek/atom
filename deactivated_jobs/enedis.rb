require 'mini_magick'
require 'sinatra'
require 'erb'

endpoint_token_url = "https://gw.hml.api.enedis.fr/v1/oauth2/token"
metering_data_base_url = "https://gw.hml.api.enedis.fr"
TWITCH='https://api.twitch.tv/helix'
FOLLOWS=TWITCH+'/channels/followed'

$access_token = ""

SCHEDULER.every '10m' do
  next if $access_token == ""
  send_lives()
end

get '/chokapeek/callback' do
  $access_token = params['access_token']
  send_lives()
  redirect '/chokapeek'
end

get '/chokapeek/enedis' do
  redirect "https://gw.hml.api.enedis.fr/group/espace-particuliers/consentement-linky/oauth2/authorize" +
    "?client_id=#{ENV['ENEDIS_CLIENT_ID']}" +
    "&redirect_uri=#{ERB::Util.url_encode('http://localhost:3030/chokapeek/callback')}" +
    "&response_type=token" +
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

  data = fetch_twitch("#{FOLLOWS}?user_id=#{user_id}&first=100")
  lives = data['data'].select { |stream| stream['type'] == 'live' }

  send_event('twitch',
    lives: lives)
end
