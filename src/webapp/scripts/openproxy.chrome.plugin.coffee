chromeExtensionDeferred = new $.Deferred()
window.addEventListener 'message', (event) ->
    if event.data.type is 'OP_CHROME_EXTENSION_INITIALIZED'
        chromeExtensionDeferred.resolve(event.data.body.version)

OpenProxy.define 'chrome', ->

    chromeExtensionDeferred.done (version) =>
        minVersion = '0.2.0'
        if semver.lt(version, minVersion)
            @notify "OpenProxy Chrome Extension needs to be updated to version #{minVersion} or greater.<br/>
Click <a href='https://github.com/openproxy/openproxy-chrome-extension'>here<a/> for the instructions."
            return

        storage = window.localStorage

        unless window.google
            @$el.html(JST['openproxy.chrome.plugin.recovery']())
            @$el.find('#reset-btn').tipsy().on 'click', (e) ->
                $target = $(e.currentTarget)
                $target.attr('title', 'Cleared. You may want to refresh page now.')
                    .tipsy('show')
                    .attr('title', 'Clear Proxy Settings')
                window.postMessage(type: "OP_PROXY_OFF", "*")
            return

        @render = do (originalRender = @render) -> ->
            result = originalRender.apply(@, arguments)
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
            result

        @popoverTemplate = do (originalPopoverTemplate = @popoverTemplate) -> (proxies) ->
            html = originalPopoverTemplate.apply(@, arguments)
            if proxies.length
                html += """
<div id="advanced-options" style='display: none'>
    <div><input id="included-hosts" type="text" placeholder='Hosts to include (e.g. *.site.com, site.com)'/></div>
    <div><input id="excluded-hosts" type="text" placeholder='Hosts to exclude'/></div>
</div>
<div id='advanced-options-toggle-container'>
    <a id="advanced-options-toggle" href="javascript:void(0)">(show advanced options)</a>
</div>
<button id='btn-activate' class='btn btn-yellow'>Activate</button>
"""
            html

        @customizePopover = (popover) ->
            $popover = $(popover.el)
            enableActivationButton = ->
                $button = $popover.find('#btn-activate')
                $button.text('Activate').prop('disabled', false) if $button.prop('disabled')
            $popover.on 'change', 'select', enableActivationButton
            resetButtonHasBeenShown = false
            $popover.on 'click', '#btn-activate', (e) ->
                split = $popover.find('select').val().split(':')
                return unless split.length is 2
                $button = $(e.target)
                $button.prop('disabled', true)
                messageBody = {host: split[0], port: parseInt(split[1], 10)}
                if $popover.find('#advanced-options').is(':visible')
                    value = $popover.find('#included-hosts').val()
                    messageBody.whitelist = value.split(',') if value
                    value = $popover.find('#excluded-hosts').val()
                    messageBody.blacklist = value.split(',') if value
                window.postMessage(type: "OP_PROXY_ON", body: messageBody, "*")
                $button.text('Activated')
                unless resetButtonHasBeenShown
                    resetButtonHasBeenShown = true
                    $resetButton = $('#reset-btn')
                    $resetButton.attr('title', 'Just so you know, button to reset proxy settings is here.')
                        .tipsy('show')
                        .attr('title', 'Clear Proxy Settings')
                    setTimeout (-> $resetButton.tipsy('hide')), 7000
            $popover.on 'click', '#advanced-options-toggle', (e) ->
                $target = $(e.currentTarget)
                $options = $popover.find('#advanced-options')
                optionsVisible = $options.is(':visible')
                $target.text("(#{if optionsVisible then 'show' else 'hide'} advanced options)")
                if storage
                    if optionsVisible
                        storage.removeItem('advanced-options-visibility')
                    else
                        storage.setItem('advanced-options-visibility', 'visible')
                enableActivationButton()
                $options.toggle()
            selectizeOptions =
                plugins: ['maintain_value'],
                persist: false,
                create: (input) ->
                    value: input, text: input
            @customizePopover = ->
                [includedHosts, excludedHosts] = (for selector in ['#included-hosts', '#excluded-hosts']
                    $popover.find(selector).selectize(selectizeOptions)[0].selectize)
                onHostsChange = (target) -> ->
                    target[if @getValue() then 'disable' else 'enable']()
                    enableActivationButton()
                includedHosts.on 'change', onHostsChange(excludedHosts)
                excludedHosts.on 'change', onHostsChange(includedHosts)
                for input in [includedHosts, excludedHosts]
                    input.trigger('change', input.$input.val())
                if storage and storage.getItem('advanced-options-visibility') is 'visible'
                    $popover.find('#advanced-options').show()
                    $popover.find('#advanced-options-toggle').text("(hide advanced options)")
            @customizePopover()
