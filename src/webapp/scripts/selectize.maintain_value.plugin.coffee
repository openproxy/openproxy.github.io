Selectize?.define 'maintain_value', (options) ->
    storage = options.storage or window.localStorage
    return unless storage

    key = 'selectize-#' + this.$input.attr('id') or throw new Error '"id" is required'
    @setup = do (originalSetup = @setup) -> ->
        @on 'change', (value) ->
            storage.setItem(key, value)
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
