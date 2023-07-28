SCHEDULER.every '1m', :first_in => 0, allow_overlapping: false do
  data = fetch_data('https://api.coinbase.com/v2/prices/BTC-EUR/spot')
  btc_price = data['data']['amount']
  btc_price = '%.2f' % btc_price.delete(',').to_f
  send_event('btcprice', value: btc_price.to_f)
end
