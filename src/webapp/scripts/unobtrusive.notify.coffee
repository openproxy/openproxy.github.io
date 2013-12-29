class UNotify # u stands for unobtrusive

    constructor: (options) ->
        @$el = $("<div class='unotify' style='display: none'></div>")
        @$el.appendTo('body')
        @_autoHideTimeout = 7000
        @content options.content if options?.content?

    show: ->
        @$el.fadeIn()
        @_autoHideIn @_autoHideTimeout
        @

    isShown: ->
        @$el.is(':visible')

    _autoHideIn: (ms) ->
        clearTimeout @_timeoutHandle if @_timeoutHandle?
        @_timeoutHandle = setTimeout =>
            @_timeoutHandle = null
            @hide()
        , ms

    content: (content) ->
        @$el.html content
        @_autoHideIn @_autoHideTimeout if @isShown() # reset the countdown
        @

    hide: ->
        @$el.fadeOut()
        @

window.UNotify = UNotify
