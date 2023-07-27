W_API='https://api.openweathermap.org/data/2.5'
# options: standard / metric / imperial
W_UNITS = 'metric' # for celsius temperature

W_API_KEY = ENV['WEATHER_KEY']
W_LAT = ENV['WEATHER_LAT']
W_LONG = ENV['WEATHER_LONG']

SCHEDULER.every '30m', :first_in => 0 do
  weather_data = fetch_data("#{W_API}/weather?lat=#{W_LAT}&lon=#{W_LONG}&units=#{W_UNITS}&appid=#{W_API_KEY}")
  detailed_info = weather_data['weather'].first
  current_temp  = weather_data['main']['temp'].to_f

  send_event('weather', {
    :temp => "#{current_temp.round(1)}",
    :condition => detailed_info['main'],
    :title => detailed_info['description'],
    :icon => "https://openweathermap.org/img/wn/#{detailed_info['icon']}@2x.png"
  })
end
