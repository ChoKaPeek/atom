# Populate the graph with some random points
points = []
(1..10).each do |i|
  points << { x: i, y: rand(50000) }
end
last_x = points.last[:x]

SCHEDULER.every '60m' do

  points.shift
  last_x += 1
  points << { x: last_x, y: rand(50000) }

  send_event('water_main_city', points: points)
end
