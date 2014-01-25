Selectize.define 'persistent_value', ->
    return unless window.localStorage

    storage = window.localStorage
    key = 'selectize-#' + this.$input.attr('id') or throw new Error '"id" is required'
    @setup = do (originalSetup = @setup) -> ->
        @on 'change', (value) ->
            localStorage.setItem(key, value)
        originalSetup.apply(@, arguments)
        valueFromLocalStorage = storage.getItem(key)
        if valueFromLocalStorage
            {valueField, labelField} = @settings
            values = valueFromLocalStorage.split(@settings.delimiter)
            for value in values
                option = {}
                option[valueField] = option[labelField] = value
                @addOption(option)
            @setValue values
