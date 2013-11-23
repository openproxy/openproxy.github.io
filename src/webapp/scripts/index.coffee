###
    Copyright (c) 2013 Stanley Shyiko
    Licensed under the MIT license.
    https://github.com/openproxy/openproxy.github.io
###

proxySwitchEnabled = false
window.addEventListener 'message', (event) ->
    if event.data.type is 'OP_CHROME_EXTENSION_INITIALIZED'
        proxySwitchEnabled = true

constructMap = (mapContainer) ->
    google.maps.visualRefresh = true
    hidden = (feature) ->
        featureType: feature,
        stylers: [visibility: 'off']
    map = new google.maps.Map mapContainer,
        zoom: 3
        center: new google.maps.LatLng(32, 0)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        mapTypeControl: false
        panControl: false
        streetViewControl: false
        scrollwheel: false, # true makes selectize go nuts (on scroll)
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
    # locking min & max zoom levels
    google.maps.event.addListener map, 'zoom_changed', do (min = 3, max = 6) -> ->
        zoom = map.getZoom()
        if zoom < min then map.setZoom(min)
        else if zoom > max then map.setZoom(max)
    # getting rid of the gray tiles at the top/bottom of the map
    previousCenter = map.getCenter()
    google.maps.event.addListener map, 'center_changed', ->
        if 85.0511 > map.getBounds().getNorthEast().lat() and map.getBounds().getSouthWest().lat() > -85.0511
            previousCenter = map.getCenter()
        else
            currentCenter = map.getCenter()
            map.panTo new google.maps.LatLng(previousCenter.lat(), currentCenter.lng())
    return map

# hack to distinguish click from double click (as latter comes in form of 'click' followed by 'dblclick')
bindToClick = (map, listener) ->
    doubleClickCatcher = null
    google.maps.event.addListener map, 'click', (event) ->
        doubleClickCatcher = setTimeout((-> listener(event)), 250)
    google.maps.event.addListener map, 'dblclick', ->
        clearTimeout doubleClickCatcher

findCountry = do ->
    geocoder = new google.maps.Geocoder()
    (latLng) ->
        deferred = new $.Deferred()
        geocoder.geocode {latLng: latLng}, (records, status) ->
            if status is google.maps.GeocoderStatus.OK
                return deferred.resolve(record) for record in records when record.types.indexOf('country') isnt -1
            deferred.reject()
        return deferred.promise()

popoverTemplate = (proxies) ->
    result = ["<span class='google-maps-popover-arrow-up'></span>"]
    if proxies.length is 0
        result.push("<div style='text-align: center; margin-bottom: 3px'>No proxies in this location</div>")
    else
        result.push("<select id='proxy-list' class='selectize' style='width:100%;'/>")
        if proxySwitchEnabled
            result.push("<button id='btn-activate' class='btn btn-yellow'>Activate</button>")
    result.join('')

constructDataSource = (countryCode) ->
    new XroxyProxyDS(countryCode: countryCode)

bindDS = ($select, ds, preloadedData) ->
    $select.selectize
        plugins: [
            'select_on_preload'
            {} = name: 'load_more', options: {fetchSize: 10}
            'copy_to_clipboard'
        ],
        preload: true,
        load: (query, callback) ->
            $control = @$control
            pageNumber = $control.data('offset') or 0
            $.when(if pageNumber then ds.fetch(pageNumber: pageNumber) else preloadedData)
            .done (proxyCollection) ->
                $control.data('offset', pageNumber + 1)
                callback(
                    for proxy in proxyCollection
                        proxyStrigified = "#{proxy.host}:#{proxy.port}"
                        value: proxyStrigified, text: proxyStrigified)

google.maps.event.addDomListener window, 'load', ->
    veil = do ->
        $veil = $('<div class="veil" style="display: none"><div class="center"></div></div>').
            appendTo($(document.body))
        new Spinner(lines: 13, length: 0, radius: 60, trail: 60).spin($veil.find('.center')[0])
        (state) ->
            $veil[if state then 'fadeIn' else 'fadeOut']()
    map = constructMap(document.getElementById('map-container'))
    mapClickListener = (event) ->
        map.setCenter(event.latLng)
        popover.hide()
        veil on
        deferredCountry = findCountry(event.latLng).done (country) ->
            countryCode = country.address_components[0].short_name # relying on ISO_3166-1 here
            proxyDS = constructDataSource(countryCode)
            proxyDS.fetch().done (proxyCollection) ->
                popover.content(popoverTemplate(proxyCollection))
                bindDS $(popover.el).find('.selectize'), proxyDS, proxyCollection
                popover.show(country.geometry.location)
                veil off
            .fail ->
                veil off
        deferredCountry.fail ->
            veil off
    bindToClick map, mapClickListener
    marker = new google.maps.Marker map: map
    google.maps.event.addListener marker, 'click', mapClickListener
    popover = new GoogleMapsPopover map: map
    # todo: bind only if proxySwitchEnabled
    $popover = $(popover.el)
    $popover.on 'click', '#btn-activate', ->
        split = ($popover.find('select').val() || '').split(':')
        return unless split.length is 2
        window.postMessage({type: "OP_PROXY_ON", body: {host: split[0], port: parseInt(split[1], 10)}}, "*")
    $.getJSON 'http://freegeoip.net/json/?callback=?', (data) ->
        clientLatLng = new google.maps.LatLng(data.latitude, data.longitude)
        findCountry(clientLatLng).done (country) ->
            marker.setPosition(country.geometry.location)
            map.setCenter(marker.getPosition())
