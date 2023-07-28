games = [
  {
  "starrail": {
    base_url: "https://sg-public-api.hoyolab.com/event/luna/os",
    act_id: "e202303301540311",
    token: {
      ltoken: ENV['SR_TOKEN'],
      ltuid: ENV['SR_TUID'],
      mhyuuid: ENV['SR_MHYUUID'],
      devicefp: ENV['SR_DEVFP'],
      devicefp_seed_id: ENV['SR_DEVFP_SEED_ID'],
      devicefp_seed_time: ENV['SR_DEVFP_SEED_TIME']
    }
  }},
  {"genshin": {
    base_url: "https://hk4e-api-os.mihoyo.com/event/sol",
    act_id: "e202102251931481",
    token: {
      ltoken: ENV['GI_TOKEN'],
      ltuid: ENV['GI_TUID'],
      mhyuuid: ENV['GI_MHYUUID'],
      devicefp: ENV['GI_DEVFP'],
      devicefp_seed_id: ENV['GI_DEVFP_SEED_ID'],
      devicefp_seed_time: ENV['GI_DEVFP_SEED_TIME']
    }
  }}
]

# Everyday at 8pm
SCHEDULER.cron '0 20 * * *', :first_in => 0 do
  games.each do |game|
    checkin(game)
  end
end

def hl_path(endpoint, game)
  return "#{game[:base_url]}/#{endpoint}?lang=en-us&act_id=#{game[:act_id]}"
end

def checkin(game)
  console.log(`Checking-in... (#{game[name]})`);
  const headers = {
    "Referer": "https://act.hoyolab.com/",
    "Cookie": `ltoken=#{game[:token][:ltoken]}; ` +
              `ltuid=#{game[:token][:ltuid]}; ` +
              "G_ENABLED_IDPS=google; " +
              `mi18nLang=en-us; ` +
              `_MHYUUID=#{game[:token][:mhyuuid]}; ` +
              `DEVICEFP=#{game[:token][:devicefp]}; ` +
              `DEVICEFP_SEED_ID=#{game[:token][:devicefp_seed_id]}; ` +
              `DEVICEFP_SEED_TIME=#{game[:token][:devicefp_seed_time]};`
  };


  data = fetch_data(hl_path("info"), headers)
  
  # Already checked in today
  if (data["is_sign"])
    send_event('hoyolab', 
      title: games[account.game],
      message: "Already checked-in today!");
  end
  
  # not a robot
  sleep((Random.new).rand(3.0..9.0))

  const response = await postJSON(url("sign"), {
    "act_id": game.act_id
  }, { maxRetry: 1, headers });

  if (!(
    response.retcode === 0 || 
    response.retcode === -5003) //Already checked in
  ) throw new Failure(response.message);
  
  request = fetch_data(hl_path("home"));
    
  reward = request['data']['awards'].
  const { awards } = request.data;
  const reward = awards.at(data.total_sign_day);
  if (reward)
    send_event('hoyolab', 
      title: games[account.game],
      message: `${reward.cnt} x ${reward.name}`);
  end  
end
