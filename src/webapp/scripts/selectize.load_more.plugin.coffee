Selectize?.define 'load_more', (options) ->

    options = $.extend
        loadTemplate: 'load more'
        loadingTemplate: 'loading'
        className: 'load-more'
    , options

    thereIsDataToFetch = true

    @refreshOptions = do (originalRefreshOptions = @refreshOptions) -> ->
        originalRefreshOptions.apply(this, arguments)
        return unless @isOpen and thereIsDataToFetch
        @$dropdown_content.append(
            "<div class='option #{options.className}' data-selectable>#{options.loadTemplate}</div>")

    @load = do (originalLoad = @load) -> (fn) ->
        originalLoad.call @, (callback) ->
            fn.call @, (results) ->
                unless results?.length is options.fetchSize
                    thereIsDataToFetch = false
                callback.call @, results

    @onOptionSelect = do (originalOptionSelect = @onOptionSelect) -> (e) ->
        $target = $(e.currentTarget)
        if $target.hasClass(options.className)
            e.preventDefault() if e.preventDefault
            return if @loading
            $target.html(options.loadingTemplate)
            @load (callback) ->
                @settings.load.apply @, [@$control_input.val() or '', callback]
        else
            originalOptionSelect.apply(this, arguments)
