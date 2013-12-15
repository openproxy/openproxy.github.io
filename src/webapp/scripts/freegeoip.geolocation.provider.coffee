class FreegeoipGeolocationProvider

    @defaults =
        serviceURL: 'http://freegeoip.net/json/'

    fetch: (callback) ->
        deferred = new $.Deferred()
        deferredGeiolocation = $.getJSON "#{FreegeoipGeolocationProvider.defaults.serviceURL}?callback=?", (data) ->
            deferred.resolve(latitude: data.latitude, longitude: data.longitude)
        deferredGeiolocation.fail ->
            deferred.rejectWith(null, arguments)
        deferred.promise()

window.FreegeoipGeolocationProvider = FreegeoipGeolocationProvider