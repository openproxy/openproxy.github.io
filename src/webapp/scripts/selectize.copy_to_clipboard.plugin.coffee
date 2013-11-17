Selectize.define 'copy_to_clipboard', ->
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
        clipboard = new ZeroClipboard()
        # todo: handle "noflash" and "wrongflash" events
        @refreshOptions = do (originalRefreshOptions = @refreshOptions) -> ->
            originalRefreshOptions.apply(@, arguments)
            clipboard.glue @$control.find('.copy-to-clipboard-button')
        originalSetup.apply(@, arguments)
