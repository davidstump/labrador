class @QueryView extends Backbone.View
  el: '[data-view=query]'

  initialize: -> @bind()

  show: ->
    $(@el).show()
    window.editor.refresh()

  hide: ->
    $(@el).hide()

  bind: ->
    app.on 'change:context', =>
      if app.get('context') is 'query' then @show() else @hide()

    $("[data-action=run]").on 'click', (e) => 
      e.preventDefault()
      app.showQuery(app.database.collection(), window.editor.getValue())