Selectize.define 'copy_to_clipboard', (options) ->

    options.clipboard ||= new ZeroClipboard()

    @setup = do (originalSetup = @setup) -> ->
        @settings.render.item = do -> (data) ->
            "
            <div class='item' style='display: inline'>
                #{data.text}
                <a class='copy-to-clipboard-button' tabindex='-1' title='Copy to Clipboard' href='javascript:void(0)'
                        data-clipboard-text='#{data.text}'>
                    <i class='icon-clipboard'></i>
                </a>
            </div>
            "
        # todo: handle "noflash" and "wrongflash" events (hiding .copy-to-clipboard-button is definitly an option here)
        @refreshOptions = do (originalRefreshOptions = @refreshOptions) -> ->
            originalRefreshOptions.apply(@, arguments)
            options.clipboard.glue @$control.find('.copy-to-clipboard-button') # todo: unglue from previous target
        originalSetup.apply(@, arguments)
