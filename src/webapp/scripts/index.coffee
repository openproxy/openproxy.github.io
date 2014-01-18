###
    Copyright (c) 2013 Stanley Shyiko
    Licensed under the MIT license.
    https://github.com/openproxy/openproxy.github.io
###

# using "load" instead of "ready" so that openproxy-chrome-extension/content_script (which is bound to run at
# "document_end") got injected prior to OpenProxy.render() call
$(window).load ->
    new OpenProxy(el: document.getElementById('application-container'), plugins: ['chrome']).render()