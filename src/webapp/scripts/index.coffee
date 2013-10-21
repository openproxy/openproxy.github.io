###
    Copyright (c) 2013 Stanley Shyiko
    Licensed under the MIT license.
    https://github.com/openproxy/openproxy.github.io
###

$.getWithYQL = (url, callback) ->
    query = encodeURIComponent("select * from html where url=\"#{url}\"")
    $.getJSON "//query.yahooapis.com/v1/public/yql?q=#{query}&format=xml&callback=?", (response) ->
        callback response.results?[0]

proxySwitchEnabled = false
window.addEventListener 'message', (event) ->
    if event.data.type is 'OP_CHROME_EXTENSION_INITIALIZED'
        proxySwitchEnabled = true

google.maps.event.addDomListener window, 'load', ->
    google.maps.visualRefresh = true
    hidden = (feature) ->
        featureType: feature,
        stylers: [visibility: 'off']
    map = new google.maps.Map document.getElementById('map-container'),
        zoom: 3
        center: new google.maps.LatLng(32, 0)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        mapTypeControl: false
        panControl: false
        streetViewControl: false
        zoomControlOptions:
            position: google.maps.ControlPosition.LEFT_CENTER
        styles: [
            hidden('administrative.province')
            hidden('administrative.locality')
            hidden('administrative.neighborhood')
            hidden('road')
            hidden('poi')
            hidden('transit')
        ]
    google.maps.event.addListener map, 'zoom_changed', do (min = 3, max = 6) -> ->
        zoom = map.getZoom()
        if zoom < min then map.setZoom(min)
        else if zoom > max then map.setZoom(max)
    veil = do ->
        $veil = $('<div class="veil" style="display: none"><div class="center"></div></div>').appendTo($(document.body))
        new Spinner(lines: 13, length: 0, radius: 60, trail: 60).spin($veil.find('.center')[0])
        (state) ->
            $veil[if state then 'fadeIn' else 'fadeOut']()
    geocoder = new google.maps.Geocoder()
    findCountry = (latLng) ->
        deferred = new $.Deferred()
        geocoder.geocode {latLng: latLng}, (records, status) ->
            if status is google.maps.GeocoderStatus.OK
                return deferred.resolve(record) for record in records when record.types.indexOf('country') isnt -1
            deferred.reject()
        return deferred
    mapClickListener = (event) ->
        map.setCenter(event.latLng)
        popover.hide()
        veil on
        deferredCountry = findCountry(event.latLng).done (country) ->
            countryCode = country.address_components[0].short_name # relying on ISO_3166-1 here
            url = "http://www.xroxy.com/proxylist.php?type=transparent&country=#{countryCode}&sort=latency"
            deferredProxyCollection = $.getWithYQL url, (data) ->
                # won't work on IE, http://goo.gl/sF8j4
                proxyCollection = []
                $response = $((new DOMParser()).parseFromString(data ? '', 'text/xml'))
                $('.row0, .row1', $response).each ->
                    tdl = $(this).find('td a')
                    proxyCollection.push
                        host: $.trim($(tdl[1]).text())
                        port: parseInt($(tdl[2]).text(), 10)
                        type: $(tdl[3]).text()
                popover.content(infoTemplate(proxyCollection)).
                    show(country.geometry.location)
                if proxySwitchEnabled
                    $('.info-window').on 'click', '.proxy-switch', (event) ->
                        proxyIndex = $(event.target).closest('tr').attr('data-index')
                        proxy = proxyCollection[proxyIndex]
                        window.postMessage({type: "OP_PROXY_ON", body: proxy}, "*")
                        return false
                veil off
            deferredProxyCollection.fail ->
                veil off
        deferredCountry.fail ->
            veil off
    doubleClickCatcher = null
    google.maps.event.addListener map, 'click', (event) ->
        doubleClickCatcher = setTimeout((-> mapClickListener(event)), 250)
    google.maps.event.addListener map, 'dblclick', ->
        clearTimeout doubleClickCatcher
    infoTemplate = (proxies) ->
        if proxies.length is 0
            '<div style="text-align: center;">No proxies in this location</div>'
        else
            trc = if proxySwitchEnabled then 'proxy-switch' else ''
            "
            <span class='google-maps-popover-arrow-up'></span>
            <table style='width: 100%;'>
                <thead><tr><th>Host</th><th>Port</th><th>Type</th></tr></thead>
                <tbody>
                    #{('<tr class="' + trc + '" data-index="' + i + '">' +
                        '<td>' + proxy.host + '</td><td>&nbsp;&nbsp;' + proxy.port +
                                '&nbsp;&nbsp;</td><td>' + proxy.type + '</td>' +
                    '</tr>' for proxy, i in proxies).join('')}
                </tbody>
            </table>
            "
    marker = new google.maps.Marker map: map
    popover = new GoogleMapsPopover map: map
    google.maps.event.addListener marker, 'click', (event) ->
        mapClickListener(event)
    $.getJSON 'http://freegeoip.net/json/?callback=?', (data) ->
        clientLatLng = new google.maps.LatLng(data.latitude, data.longitude)
        findCountry(clientLatLng).done (country) ->
            marker.setPosition(country.geometry.location)
            map.setCenter(marker.getPosition())
