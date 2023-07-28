HL_GAMES = [
  {
    name: "Honkai Star Rail",
    base_url: "https://sg-public-api.hoyolab.com/event/luna/os",
    act_id: "e202303301540311"
  },
  {
    name: "Genshin Impact",
    base_url: "https://hk4e-api-os.mihoyo.com/event/sol",
    act_id: "e202102251931481"
  }
]

# Everyday at 8pm
SCHEDULER.cron '0 20 * * *', :first_in => 1 do
  checkin()
end

def hl_path(endpoint, game)
  return "#{game[:base_url]}/#{endpoint}?lang=en-us&act_id=#{game[:act_id]}"
end

def checkin()
  items = []
  HL_GAMES.each do |game|
    puts "Checking-in #{game[:name]}..."
    headers = {
      "Referer" => "https://act.hoyolab.com/",
      "Cookie" => "ltoken=#{ENV['HL_TOKEN']}; " +
                "ltuid=#{ENV['HL_TUID']}; " +
                "G_ENABLED_IDPS=google; " +
                "mi18nLang=en-us; " +
                "_MHYUUID=#{ENV['HL_MHYUUID']}; " +
                "DEVICEFP=#{ENV['HL_DEVFP']}; " +
                "DEVICEFP_SEED_ID=#{ENV['HL_DEVFP_SEED_ID']}; " +
                "DEVICEFP_SEED_TIME=#{ENV['HL_DEVFP_SEED_TIME']};"
    }

    info = fetch_data(hl_path("info", game), headers)
    
    # Not checked in today
    if (!info['data']["is_sign"])
      # not a robot
      sleep((Random.new).rand(3.0..9.0))

      signed = post_data(hl_path("sign", game), { "act_id" => game[:act_id] }, headers)
      dump(signed)
    end

    home = fetch_data(hl_path("home", game))
      
    reward = home['data']['awards'][info['data']["total_sign_day"]]
    if (reward)
      items << { 
        title: game[:name],
        message: "#{reward['cnt']} x #{reward['name']}",
        arrow: "icon-ok-sign",
        color: "green"
      }
    else
      items << {
        title: game[:name],
        message: "Error",
        arrow: "icon-warning-sign",
        color: "red"
      }
    end 
  end
  send_event('hoyolab', items: items)
end
