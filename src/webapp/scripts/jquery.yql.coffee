$.getWithYQL = (url, callback) ->
    query = encodeURIComponent("select * from html where url=\"#{url}\"")
    deferred = $.Deferred()
    $.getJSON "#{$.getWithYQL.defaults.serviceURL}?q=#{query}&format=xml&diagnostics=true&callback=?", (response) ->
        diagnostics = response.query?.diagnostics?.url
        if diagnostics?.error
            deferred.rejectWith null, [null, diagnostics['http-status-code'], diagnostics['http-status-message']]
        else if not response.results?.length > 0
            deferred.rejectWith null
        else
            callback response.results?[0]
    .then (-> deferred.resolveWith(null, arguments)), (-> deferred.rejectWith(null, arguments))
    deferred.promise()

$.getWithYQL.defaults =
    serviceURL: 'http://query.yahooapis.com/v1/public/yql'
