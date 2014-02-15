Selectize?.define 'copy_to_clipboard', ->
    return unless ZeroClipboard.detectFlashSupport()

    clipboard = new ZeroClipboard()
    clipboard.on 'load', ->
        $bridge = $(clipboard.htmlBridge)
        $bridge.tipsy({gravity: 'sw'})
        clipboard.on 'complete', ->
            $bridge.attr('title', 'Copied').tipsy('show')

    @setup = do (originalSetup = @setup) -> ->
        @settings.render.item = (data) ->
            "
            <div class='item' style='display: inline'>
                #{data.text}
                <a class='copy-to-clipboard-button' tabindex='-1' href='javascript:void(0)'
                   title='Copy To Clipboard' data-clipboard-text='#{data.text}'>
                    <i class='icon-clipboard'></i>
                </a>
            </div>
            "
        @refreshOptions = do (originalRefreshOptions = @refreshOptions) -> ->
            originalRefreshOptions.apply(@, arguments)
            clipboard.unglue $target if $target?
            $target = @$control.find('.copy-to-clipboard-button')
            clipboard.glue $target
        originalSetup.apply(@, arguments)
