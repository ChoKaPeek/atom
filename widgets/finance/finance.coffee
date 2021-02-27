class Dashing.Finance extends Dashing.Widget
  @accessor 'price', Dashing.AnimatedValue
  @accessor 'formatted_price', ->
    if @get('price')
      price = parseFloat(@get('price'))
  @accessor 'change', Dashing.AnimatedValue
  @accessor 'formatted_change', ->
    if @get('change')
      price = parseFloat(@get('change'))
