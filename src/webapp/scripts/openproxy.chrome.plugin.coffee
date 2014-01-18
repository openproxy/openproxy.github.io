chromeExtensionDeferred = new $.Deferred()
window.addEventListener 'message', (event) ->
    if event.data.type is 'OP_CHROME_EXTENSION_INITIALIZED'
        chromeExtensionDeferred.resolve()

OpenProxy.define 'chrome', ->

    chromeExtensionDeferred.done =>

        unless window.google
            @$el.html($('#application-chrome-recovery-template').html())
            @$el.find('#reset-btn').tipsy().on 'click', (e) ->
                $target = $(e.currentTarget)
                $target.attr('title', 'Cleared. You may want to refresh page now.')
                    .tipsy('show')
                    .attr('title', 'Clear Proxy Settings')
                window.postMessage(type: "OP_PROXY_OFF", "*")
            return

        @popoverTemplate = do (originalPopoverTemplate = @popoverTemplate) -> (proxies) ->
            html = originalPopoverTemplate.apply(@, arguments)
            if proxies.length
                html += "<button id='btn-activate' class='btn btn-yellow'>Activate</button>"
            html

        @customizePopover = (popover) ->
            $popover = $(popover.el)
            $popover.on 'change', 'select', ->
                $button = $popover.find('#btn-activate')
                $button.text('Activate').prop('disabled', false)
            resetButtonHasBeenShown = false
            $popover.on 'click', '#btn-activate', (e) ->
                split = $popover.find('select').val().split(':')
                return unless split.length is 2
                $button = $(e.target)
                $button.prop('disabled', true)
                window.postMessage(type: "OP_PROXY_ON", body: {host: split[0], port: parseInt(split[1], 10)}, "*")
                $button.text('Activated')
                unless resetButtonHasBeenShown
                    resetButtonHasBeenShown = true
                    $resetButton = $('#reset-btn')
                    $resetButton.attr('title', 'Just so you know, button to reset proxy settings is here.')
                        .tipsy('show')
                        .attr('title', 'Clear Proxy Settings')
                    setTimeout (-> $resetButton.tipsy('hide')), 7000
            $toolbar = $('#toolbar')
            $('''
<span style="display: none">
    <span class="bb-divider"></span>
    <a id="reset-btn" class="icon" title="Clear Proxy Settings" href="javascript:void(0)" data-tipsy-gravity="nw">
        <i class="icon-unlink"></i>
    </a>
</span>
            ''').appendTo($toolbar).fadeIn().find('#reset-btn').tipsy().on 'click', (e) ->
                $target = $(e.currentTarget)
                $target.attr('title', 'Cleared').tipsy('show').attr('title', 'Clear Proxy Settings')
                window.postMessage(type: "OP_PROXY_OFF", "*")
            @customizePopover = null
