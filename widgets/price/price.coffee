class Dashing.Price extends Dashing.Widget
  @accessor 'value', Dashing.AnimatedValue
  @accessor 'price', ->
    if @get('value')
      price = parseFloat(@get('value'))
