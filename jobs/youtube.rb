require "erb"

BASE='https://youtube.googleapis.com/youtube/v3'
SUBS=BASE+'/subscriptions'
CHANS=BASE+'/channels'
PLAYS=BASE+'/playlistItems'
VIDS=BASE+'/videos'

SUFFIX="&maxResults=50&key=#{ENV['GOOGLE_KEY']}"
SUFFIX_3="&maxResults=3&key=#{ENV['GOOGLE_KEY']}"

$yt_access_token = ""

# separate this job to greatly reduce api usage
SCHEDULER.every '10h', mutex: 'playlist0' do
  next if $yt_access_token == ""
  $playlists = get_playlists()
end

SCHEDULER.every '30m', mutex: 'playlist0' do
  next if $yt_access_token == ""
  send_videos($playlists)
end

get '/chokapeek/youtube/callback' do
  if params['code']
      data = post_data_form("https://oauth2.googleapis.com/token?client_id=#{ENV['YT_CLIENT_ID']}" +
                          "&client_secret=#{ENV['YT_SECRET']}" +
                          "&code=#{params['code']}" +
                          "&grant_type=authorization_code" +
                          "&redirect_uri=#{ERB::Util.url_encode('http://localhost:3030/chokapeek/youtube/callback')}"
                         )
    if data['access_token']
      $yt_access_token = data['access_token']
      $playlists = get_playlists()
      send_videos($playlists)
      redirect '/chokapeek'
    end
  end
end

get '/chokapeek/youtube' do
  redirect "https://accounts.google.com/o/oauth2/v2/auth" +
    "?client_id=#{ENV['YT_CLIENT_ID']}" +
    "&redirect_uri=#{ERB::Util.url_encode('http://localhost:3030/chokapeek/youtube/callback')}" +
    "&response_type=code" +
    "&scope=#{ERB::Util.url_encode('https://www.googleapis.com/auth/youtube.readonly')}"
end

def fetch_yt(path)
  headers = {
    'Authorization' => "Bearer #{$yt_access_token}"
  }
  return fetch_data(path, headers)
end

def get_playlists()
  data = fetch_yt("#{SUBS}?part=snippet&channelId=#{ENV['YOUTUBE_CHAN_ID']}#{SUFFIX}")
  playlists = []
  loop do
    subs = []
    data['items'].each do |i|
      if i['kind'] == 'youtube#subscription'
        subs << i['snippet']['resourceId']['channelId']
      end
    end

    chans = fetch_yt("#{CHANS}?part=contentDetails&id=#{subs.join(',')}#{SUFFIX}")
    chans['items'].each do |j|
      playlists << j['contentDetails']['relatedPlaylists']['uploads']
    end

    break unless data['nextPageToken']
    data = fetch_yt("#{SUBS}?part=snippet&channelId=#{ENV['YOUTUBE_CHAN_ID']}#{SUFFIX}&pageToken=#{data['nextPageToken']}")
  end
  return playlists
end

def send_videos(playlists)
  videos = []
  true_videos = []

  return if playlists.empty?

  playlists.each do |p|
    data = fetch_yt("#{PLAYS}?part=contentDetails&playlistId=#{p}#{SUFFIX_3}")
    data['items'].each do |i|
      if i['kind'] == 'youtube#playlistItem'
        videos << i['contentDetails']['videoId']
      end
    end
  end

  videos.each_slice(50) do |chunk|
    true_videos.concat(fetch_yt("#{VIDS}?part=snippet&id=#{chunk.join(',')}#{SUFFIX}")['items'])
  end

  true_videos = true_videos.sort_by! { |k| k['snippet']['publishedAt'] }.reverse!.take(5)

  list = []
  true_videos.each do |vid|
    list << {
      thumb: vid['snippet']['thumbnails']['default']['url'],
      title: vid['snippet']['title']
    }
  end

  send_event('youtube', list: list)
end
