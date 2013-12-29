class XroxyProxyDS

    constructor: (options) ->
        @countryCode = options.countryCode or throw new Error '"countryCode" is required'

    @defaults =
        serviceURL: 'http://www.xroxy.com/proxylist.php'

    name: 'xroxy.com'

    fetch: (options) ->
        pageNumber = options?.pageNumber || 0
        serviceURL = XroxyProxyDS.defaults.serviceURL
        url = "#{XroxyProxyDS.defaults.serviceURL}?sort=latency&type=transparent" +
            "&country=#{@countryCode}&pnum=#{pageNumber}"
        deferred = new $.Deferred()
        deferredProxyCollection = $.getWithYQL url, (data) ->
            proxyCollection = []
            # fixme: won't work on IE, http://goo.gl/sF8j4
            $response = $((new DOMParser()).parseFromString(data ? '', 'text/xml'))
            $('.row0, .row1', $response).each ->
                tdl = $(this).find('td a')
                proxyCollection.push
                    host: $.trim($(tdl[1]).text())
                    port: parseInt($(tdl[2]).text(), 10)
                    type: $(tdl[3]).text()
            deferred.resolve(proxyCollection)
        deferredProxyCollection.fail ->
            deferred.rejectWith(null, arguments)
        deferred.promise()

window.XroxyProxyDS = XroxyProxyDS