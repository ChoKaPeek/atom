class Dashing.Finance extends Dashing.Widget
  @accessor 'price', Dashing.AnimatedValue
  @accessor 'finance', ->
    if @get('price')
      price = parseFloat(@get('price'))
