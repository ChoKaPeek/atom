require 'mini_magick'

SCHEDULER.every '1h', first_in: 0 do
  # map
  image = MiniMagick::Image.open('https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/10/352/518')
  # pollution overlay
  overlay = MiniMagick::Image.open('https://magellan.airparif.asso.fr/geoserver/apisHorAir/wms?service=WMS&request=GetMap&layers=apisHorAir%3Aindice_api&styles=indice&format=image%2Fpng8&transparent=true&version=1.3&tiled=true&authkey=7d2a2d15-2887-2d22-3754-bb93ac846ad6&width=256&height=256&crs=EPSG%3A3857&bbox=234814.5508920615,6222585.598639631,273950.3093740717,6261721.357121641')

  # Overlay
  image.composite(overlay) do |c|
    c.compose "Over"
    c.geometry "+0+0"
  end

  # make transparent background
  image.combine_options do |c|
    c.fill 'none'
    c.draw 'color 0,0 floodfill'
  end

  headers = {
    'X-Api-Key' => ENV['AIRPARIF_KEY']
  }
 
  data = fetch_data("https://api.airparif.asso.fr/indices/prevision/commune?insee=#{ENV['INSEE_CODE']}", headers)
  jour = data[ENV['INSEE_CODE']][0]
  demain = data[ENV['INSEE_CODE']][1]

  send_event('airparif',
             image: 'data:image/png;base64,' + Base64.encode64(image.to_blob),
             jour: {
               no2: jour['no2'],
               o3: jour['o3'],
               pm10: jour['pm10'],
               pm25: jour['pm25'],
               indice: jour['indice']
             },
             demain: { indice: demain['indice'] })
end
