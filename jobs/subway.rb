API = "https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring"
LINE1 = "STIF:Line::C01210" # 189
LINE2 = "STIF:Line::C01210:" # 189
STOP1 = "STIF:StopPoint:Q:23785:" # Porte de saint cloud
SUBWAY_FILES = "https://www.ratp.fr/sites/default/files/network/"

def get_next(line, stop)
    data = fetch_data("#{API}?MonitoringRef=#{stop}&LineRef=#{line}")
    result = []
    data['Siri']['ServiceDelivery']['StopMonitoringDelivery']['MonitoredStopVisit'].each do |monitored|
      res = []
      datetime = monitored['MonitoredVehicleJourney']['MonitoredCall']['ExpectedDepartureTime']
      res << datetime == "" ? "-" : ((Time.parse(datetime) - Time.now) / 60).to_i # datetime
      res << monitored['MonitoredVehicleJourney']['DestinationName']['value'] # destination
      result << res
    end

    return result
end

SCHEDULER.every '1m', first_in: 0 do
    time = Time.now
    lines = []
    if 0 < time.hour && time.hour < 5
        noct1 = get_next(LINE1, STOP1)
        lines << {
            name: "Noct. 21",
            icon: SUBWAY_FILES + "noctilien/ligne21.svg",
            in1: {name: noct1[0][1], values: noct1[0][0]},
            in2: {name: noct1[1][1], values: noct1[1][0]},
            out1: {name: noct1[2][1], values: noct1[2][0]},
            out2: {name: noct1[3][1], values: noct1[3][0]}
        }
    else
        bus1 = get_next(LINE1, STOP1)
        lines << {
            name: "Bus 189",
            icon: SUBWAY_FILES + "bus/ligne189.svg",
            in1: {name: bus1[0][1], values: bus1[0][0]},
            in2: {name: bus1[1][1], values: bus1[1][0]},
            out1: {name: bus1[2][1], values: bus1[2][0]},
            out2: {name: bus1[3][1], values: bus1[3][0]}
        }
    end
    bus2 = get_next(LINE2, STOP1)
    lines << {
        name: "Metro 9",
        icon: SUBWAY_FILES + "metro/ligne9.svg",
        in1: {name: bus2[0][1], values: bus2[0][0]},
        in2: {name: bus2[1][1], values: bus2[1][0]},
        out1: {name: bus2[2][1], values: bus2[2][0]},
        out2: {name: bus2[3][1], values: bus2[3][0]}
    }
    
    send_event("subway", {items: lines})
end
