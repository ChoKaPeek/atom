
require 'open-uri'
require 'json'

# Unofficial API but it works great
API = "https://api-ratp.pierre-grimaud.fr/v4/schedules/"

def get_next(type, path)
    begin
        url = "#{API}#{type}/#{path}"
        output = URI.open(url)
        timetables = JSON.parse(output.read)
        schedules = timetables['result']['schedules']
        res = Array.new(schedules.count) { |e| e = [] }
        for i in 0...schedules.count
            if schedules[i]['message'] == "A l'approche"
                res[i][0] = "0"
            else
                next_one = schedules[i]['message'].scan(/\d+/).first
                res[i][0] = next_one.to_s.empty? ? "-" : next_one
            end
            res[i][1] = schedules[i]['destination']
        end
        return res
    rescue
        return res
    end
end

SCHEDULER.every '1m', first_in: 0 do |job|
    time = Time.new
    if 0 < time.hour && time.hour < 5
        noct1 = get_next('noctiliens', 'n21/rue+des+jardins/A+R')
        lines = [
            {
                name: "Noct. 21",
                icon: "noctilien/ligne21.svg",
                in1: {name: noct1[0][1], values: noct1[0][0]},
                in2: {name: noct1[1][1], values: noct1[1][0]},
                out1: {name: noct1[2][1], values: noct1[2][0]},
                out2: {name: noct1[3][1], values: noct1[3][0]}
            }
        ]
    else
        bus1 = get_next('buses', '172/centre+commercial/A+R')
        bus2 = get_next('buses', '186/belvedere/A+R')
        lines = [
            {
                name: "Bus 172",
                icon: "bus/ligne172.svg",
                in1: {name: bus1[0][1], values: bus1[0][0]},
                in2: {name: bus1[1][1], values: bus1[1][0]},
                out1: {name: bus1[2][1], values: bus1[2][0]},
                out2: {name: bus1[3][1], values: bus1[3][0]}
            },
            {
                name: "Bus 186",
                icon: "bus/ligne186.svg",
                in1: {name: bus2[0][1], values: bus2[0][0]},
                in2: {name: bus2[1][1], values: bus2[1][0]},
                out1: {name: bus2[2][1], values: bus2[2][0]},
                out2: {name: bus2[3][1], values: bus2[3][0]}
            }
        ]
    end
    send_event("subway", {items: lines})
end
