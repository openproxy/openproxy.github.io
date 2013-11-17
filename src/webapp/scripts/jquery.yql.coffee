$.getWithYQL = (url, callback) ->
    query = encodeURIComponent("select * from html where url=\"#{url}\"")
    $.getJSON "//query.yahooapis.com/v1/public/yql?q=#{query}&format=xml&callback=?", (response) ->
        callback response.results?[0]
