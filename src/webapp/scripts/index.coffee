###
    Copyright (c) 2013 Stanley Shyiko
    Licensed under the MIT license.
    https://github.com/openproxy/openproxy.github.io
###

google.maps.event.addDomListener window, 'load', () ->
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
        styles: [
            hidden('administrative.province')
            hidden('administrative.locality')
            hidden('administrative.neighborhood')
            hidden('road')
            hidden('poi')
            hidden('transit')
        ]
    google.maps.event.addListener map, 'zoom_changed', ((min, max) ->
        return ->
            zoom = map.getZoom()
            if zoom < min then map.setZoom(min)
            else if zoom > max then map.setZoom(max)
    )(3, 6)
    geocoder = new google.maps.Geocoder()
    findCountry = (latLng) ->
        deferred = new $.Deferred()
        geocoder.geocode {latLng: latLng}, (records, status) ->
            if status is google.maps.GeocoderStatus.OK
                return deferred.resolve(record) for record in records when record.types.indexOf('country') isnt -1
            deferred.reject()
        return deferred
    google.maps.event.addListener map, 'click', (event) ->
        map.setCenter(event.latLng)
        findCountry(event.latLng).done (country) ->
            countryCode = country.address_components[0].short_name
            url = "http://www.xroxy.com/proxylist.php?type=transparent&country=#{countryCode}&sort=latency"
            $.get url, (data) ->
                # won't work on IE, http://goo.gl/sF8j4
                proxyCollection = []
                $response = $((new DOMParser()).parseFromString(data.responseText, 'text/xml'))
                $('.row0, .row1', $response).each ->
                    tdl = $(this).find('td a')
                    proxyCollection.push
                        host: $.trim($(tdl[1]).text())
                        port: parseInt($(tdl[2]).text(), 10)
                        type: $(tdl[3]).text()
                infoWindow.setPosition(country.geometry.location)
                infoWindow.setContent(infoTemplate(proxyCollection))
                infoWindow.open(map)
                if proxySwitchEnabled
                    $('.info-window').on 'click', '.proxy-switch', (event) ->
                        proxyIndex = $(event.target).closest('tr').attr('data-index')
                        proxy = proxyCollection[proxyIndex]
                        window.postMessage({type: "OP_PROXY_ON", body: proxy}, "*")
                        return false
    # marker.setPosition(country.geometry.location)
    proxySwitchEnabled = false
    infoTemplate = (proxies) ->
        if proxies.length is 0
            '<div>No proxies in this location</div>'
        else
            trc = if proxySwitchEnabled then 'proxy-switch' else ''
            "<div class='info-window'>
                <table>
                    <thead><tr><th>Host</th><th>Port</th><th>Type</th></tr></thead>
                    <tbody>
                        #{('<tr class="' + trc + '" data-index="' + i + '">' +
                            '<td>' + proxy.host + '</td><td>' + proxy.port + '</td><td>' + proxy.type + '</td>' +
                        '</tr>' for proxy, i in proxies).join('')}
                    </tbody>
                </table>
            </div>"
    infoWindow = new google.maps.InfoWindow
    marker = new google.maps.Marker map: map
    google.maps.event.addListener marker, 'click', ->
        infoWindow.open(map, marker)
    $.getJSON 'http://freegeoip.net/json/?callback=?', (data) ->
        clientLatLng = new google.maps.LatLng(data.latitude, data.longitude)
        map.setCenter(clientLatLng)
        findCountry(clientLatLng).done (country) ->
            marker.setPosition(country.geometry.location)
    window.addEventListener 'message', (event) ->
        if event.data.type is 'OP_CHROME_EXTENSION_INITIALIZED'
            proxySwitchEnabled = true
