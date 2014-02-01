if window.applicationCache
    deferredUpdateReady = new $.Deferred()
    window.applicationCache.addEventListener 'updateready', deferredUpdateReady.resolve

# using "load" instead of "ready" so that openproxy-chrome-extension/content_script (which is bound to run at
# "document_end") got injected prior to OpenProxy.render() call
$(window).load ->
    openproxy = new OpenProxy(el: document.getElementById('application-container'), plugins: ['chrome']).render()

    deferredUpdateReady?.then ->
        openproxy.notify '''A new version of OpenProxy is available.<br/> Please
<a href="javascript:window.location.reload()">refresh<a/> the page to complete an update.'''
