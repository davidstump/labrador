class @App extends Backbone.Model
  
  defaults:
    limit: 250
    context: 'content'

  initialize: ->
    $ =>
      @$main = $("[data-view=main]")
      @$collections = $("ul[data-view=collections]")      
      @database = new Database(path: serverExports.app.path)
      @tableView = new TableView(model: @database, el: ".fixed-table-container table:first")
      @progressView = new ProgressView()  
      @headerView = new HeaderView()
      @footerView = new FooterView(model: @database)
      @queryView = new QueryView(model: @database)
      Popover.init()
      @resizeBody()
      @bind()


  bind: ->
    # Select the first collection on window load
    $(window).on 'load', => 
      @$collections.find("li a").first().trigger('click')

    @tableView.off('scroll').on 'scroll', => 
      Popover.hide() if Popover.isVisible()

    $(window).on 'resize', => @resizeBody()

    @$collections.on 'click', 'li a', (e) =>
      e.preventDefault()
      $target = $(e.target)
      @$collections.find("li").removeClass('active')
      $target.parent('li').addClass('active')
      collection = $target.attr('data-collection')
      adapter = $target.attr('data-adapter')
      @database.set(adapter: adapter)
      @tableView.showLoading()
      @showContext(collection)

    $(document).on 'keydown', (e) => 
      switch e.keyCode
        when 27
          e.preventDefault()
          @hideTooltips() 

    @database.on 'error', (data) => @showError("Caught error from database: #{data.error}")

    window.editor = CodeMirror.fromTextArea(document.getElementById("code"),
      mode: 'text/x-sql'
      indentWithTabs: true
      smartIndent: true
      lineNumbers: true
      matchBrackets: true
      autofocus: true
    ) 

  
  resizeBody: ->
    @$main.css(height: $(window).height() - 104)


  hideTooltips: ->
    app.trigger('hide:tooltips')


  showSchema: (collection) ->
    collection ?= @database.collection()
    @set(context: 'schema')
    @database.schema collection, (error, data) => @database.set({data})


  showContent: (collection) ->
    collection ?= @database.collection()
    @set(context: 'content')
    @database.find collection, limit: @get('limit'), (err, data) => @database.set({data: data})

  showQuery: (collection, query = "") ->
    collection ?= @database.collection()
    @set(context: 'query')
    unless query is ""
      @database.query collection, query, (error, data) => @database.set({data})

  refreshContext: ->
    collection = @database.collection()
    switch @get('context')
      when "schema"  then @showSchema(collection)
      when "content" then @showContent(collection)
      when "query"   then @showQuery(collection)


  showContext: (collection) ->
    switch @get('context')
      when "schema"  then @showSchema(collection)
      when "content" then @showContent(collection)
      when "query"   then @showQuery(collection)

  
  isEditable: ->
    return false unless @database.collection()?
    switch @get('context')
      when "schema"  then false
      when "content" then true
      when "query"   then true


  showError: (error) ->
    Modal.alert
      title: I18n.t("modals.error.title")
      body: error
      ok:
        label: I18n.t("modals.ok")
        onclick: => Modal.close()


@app = new App()