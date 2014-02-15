Selectize?.define 'select_on_preload', ->
    return unless this.settings.preload

    originalOnSearchChange = @onSearchChange
    # unthrottle until first 'load' event
    @onSearchChange = (value) ->
        fn = @settings.load
        return unless fn
        return if @loadedSearches.hasOwnProperty(value)
        @loadedSearches[value] = true
        @load (callback) ->
            fn.apply @, [value, callback]

    @setup = do (originalSetup = @setup) -> ->
        @on 'load', loadCallback = (results) ->
            @setValue(results[0][@settings.valueField]) if results?.length
            @onSearchChange = originalOnSearchChange
            @off('load', loadCallback)
        originalSetup.apply(@, arguments)
