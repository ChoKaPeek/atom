require 'mini_magick'

BASE='https://youtube.googleapis.com/youtube/v3'
SUBS=BASE+'/subscriptions'
CHANS=BASE+'/channels'
PLAYS=BASE+'/playlistItems'
VIDS=BASE+'/videos'

SUFFIX="&maxResults=50&key=#{ENV['GOOGLE_KEY']}"
SUFFIX_5="&maxResults=3&key=#{ENV['GOOGLE_KEY']}"

# slightly delay
SCHEDULER.in '10s' do
  $playlists = get_playlists()
  send_videos($playlists)
end

# separate this job to greatly reduce api usage
SCHEDULER.every '10h', mutex: 'playlist0' do
  $playlists = get_playlists()
end

SCHEDULER.every '10m', mutex: 'playlist0' do
  send_videos($playlists)
end

def get_playlists()
  data = fetch_data("#{SUBS}?part=id&channelId=#{ENV['YOUTUBE_CHAN_ID']}#{SUFFIX}")
  playlists = []
  loop do
    subs = []
    data['items'].each do |i|
      if i['kind'] == 'youtube#subscription'
        subs << i['snippet']['resourceId']['channelId']
      end
    end

    chans = fetch_data("#{CHANS}?part=contentDetails&id=#{subs.join('%2C')}#{SUFFIX}")
    chans['items'].each do |j|
      playlists << j['contentDetails']['relatedPlaylists']['uploads']
    end

    break unless data['nextPageToken']
    data = fetch_data("#{SUBS}?part=id&channelId=#{ENV['YOUTUBE_CHAN_ID']}#{SUFFIX}&pageToken=#{data['nextPageToken']}")
  end
  return playlists
end

def send_videos(playlists)
  videos = []
  true_videos = []

  puts playlists
  return if playlists.empty?
  
  playlists.each do |p|
    data = fetch_data("#{PLAYS}?part=contentDetails&playlistId=#{p}#{SUFFIX_3}")
    data['items'].each do |i|
      if i['kind'] == 'youtube#playlistItem'
        videos << i['contentDetails']['videoId']
      end
    end
  end

  videos.each_slice(50) do |chunk|
    true_videos.concat(fetch_data("#{VIDS}?part=snippet&id=#{chunk.join('%2C')}#{SUFFIX}")['items'])
  end

  true_videos.sort_by! { |k| k['snippet']['publishedAt'] }.reverse!.take(3)

  images = []
  true_videos.each do |vid|
    images << 'data:image/png;base64,' + Base64.encode64(MiniMagick::Image.open(vid['snippet']['thumbnails']['default']['url']).to_blob)
  end

  send_event('youtube',
    title1: true_videos.length > 0 ? true_videos[0]['snippet']['title'] : '',
    thumb1: images.length > 0 ? images[0] : '',
    title2: true_videos.length > 1 ? true_videos[1]['snippet']['title'] : '',
    thumb2: images.length > 1 ? images[1] : '',
    title3: true_videos.length > 2 ? true_videos[2]['snippet']['title'] : '',
    thumb3: images.length > 2 ? images[2] : '')
end
