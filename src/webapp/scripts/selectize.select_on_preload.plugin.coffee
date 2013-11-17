Selectize.define 'select_on_preload', ->
    return unless this.settings.preload
    @setup = do (originalSetup = @setup) -> ->
        @on 'load', loadCallback = (results) ->
            @setValue(results[0][@settings.valueField]) if results?.length
            @off('load', loadCallback)
        originalSetup.apply(@, arguments)
