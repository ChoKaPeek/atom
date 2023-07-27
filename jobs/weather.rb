W_API='https://api.openweathermap.org/data/3.0'
# options: metric / imperial
W_UNITS = 'metric'

W_API_KEY = ENV['WEATHER_KEY']
W_LAT = ENV['WEATHER_LAT']
W_LONG = ENV['WEATHER_LONG']

SCHEDULER.every '30m', :first_in => 0 do
  weather_data = fetch_data("#{W_API}/weather?lat=#{W_LAT}&lon=#{W_LONG}&units=#{W_UNITS}&appid=#{W_API_KEY}")
  detailed_info = weather_data['current']['weather'].first
  current_temp  = weather_data['current']['temp'].to_f.round

  send_event('weather', { :temp => "#{current_temp}",
                          :condition => detailed_info['main'],
                          :title => detailed_info['description'],
                          :climacon => weather_data['daily'].first['summary']})
end
