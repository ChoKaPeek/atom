API = "https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring"
SUBWAY_FILES = "https://www.ratp.fr/sites/default/files/network/"

def fetch_prim(path)
  headers = { 'apiKey' => ENV['PRIM_API_KEY'] }
  return fetch_data(path, headers)
end

def get_next(line, stop)
    data = fetch_prim("#{API}?MonitoringRef=#{stop}&LineRef=#{line}")
    result = []
    delivery = data['Siri']['ServiceDelivery']['StopMonitoringDelivery'][0]
    delivery['MonitoredStopVisit'].each do |monitored|
      datetime = monitored['MonitoredVehicleJourney']['MonitoredCall']['ExpectedDepartureTime']
      result << {
        minutes: datetime == "" ? "-" : "#{((Time.parse(datetime) - Time.now) / 60).to_i}",
        destination: monitored['MonitoredVehicleJourney']['DestinationName'][0]['value']
      }
    end

    return result
end

SCHEDULER.every '1m', :first_in => 0 do
    time = Time.now
    lines = []
    if 0 < time.hour && time.hour < 5
        noct1 = get_next(ENV['PRIM_LINE1'], ENV['PRIM_STOP1'])
        lines << {
            name: "Noct. 21",
            icon: SUBWAY_FILES + "noctilien/ligne21.svg",
            in1: {name: noct1[0][:destination], values: noct1[0][:minutes]},
            in2: {name: noct1[1][:destination], values: noct1[1][:minutes]},
            out1: {name: "-", values: ""},
            out2: {name: "-", values: ""}
        }
    else
        bus1 = get_next(ENV['PRIM_LINE1'], ENV['PRIM_STOP_IN1'])
        lines << {
            name: "Bus 189",
            icon: SUBWAY_FILES + "bus/ligne189.svg",
            in1: {name: bus1[0][:destination], values: bus1[0][:minutes]},
            in2: {name: bus1[1][:destination], values: bus1[1][:minutes]},
            out1: {name: "Terminus", values: ""},
            out2: {name: "", values: ""}
        }
    end
    in2 = get_next(ENV['PRIM_LINE2'], ENV['PRIM_STOP_IN2'])
    out2 = get_next(ENV['PRIM_LINE2'], ENV['PRIM_STOP_OUT2'])
    lines << {
        name: "Metro 9",
        icon: SUBWAY_FILES + "metro/ligne9.svg",
        in1: {name: in2[0][:destination], values: in2[0][:minutes]},
        in2: {name: in2[1][:destination], values: in2[1][:minutes]},
        out1: {name: out2[0][:destination], values: out2[0][:minutes]},
        out2: {name: out2[1][:destination], values: out2[1][:minutes]},
    }
    send_event("subway", {items: lines})
end
