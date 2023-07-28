SCHEDULER.every '1m', :first_in => 0 do
  data = fetch_data('https://api.coinbase.com/v2/prices/ETH-EUR/spot')
  eth_price = data['data']['amount']
  eth_price = '%.2f' % eth_price.to_f
  send_event('ethprice', value: eth_price.to_f)
end
