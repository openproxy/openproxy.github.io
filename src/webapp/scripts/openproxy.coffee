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
        mapBounds = map.getBounds()
        return unless mapBounds
        if 85.0511 > mapBounds.getNorthEast().lat() and mapBounds.getSouthWest().lat() > -85.0511
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

# selectize.load bridge
selectizeProxyListProvider = (proxyListProvider, preloadedData) ->
    (query, callback) ->
        $control = @$control
        pageNumber = $control.data('offset') or 0
        $.when(if pageNumber then proxyListProvider.fetch(pageNumber: pageNumber) else preloadedData)
        .done (proxyCollection) ->
            $control.data('offset', pageNumber + 1)
            callback(
                for proxy in proxyCollection
                    proxyStrigified = "#{proxy.host}:#{proxy.port}"
                    value: proxyStrigified, text: proxyStrigified)

class OpenProxy

    constructor: (options) ->
        @$el = $(options.el)
        @initializePlugins options.plugins

    veil: (show) ->
        unless @$veil
            @$veil = $('<div class="veil" style="display: none"><div class="center"></div></div>').
                appendTo($(document.body))
            new Spinner(lines: 13, length: 0, radius: 60, trail: 60).spin(@$veil.find('.center')[0])
        @$veil[if show then 'show' else 'hide']()

    determineCountryByLatLng: (latLng) ->
        @geocoder ||= new google.maps.Geocoder()
        deferred = new $.Deferred()
        @geocoder.geocode {latLng: latLng}, (records, status) ->
            if status is google.maps.GeocoderStatus.OK
                return deferred.resolve(record) for record in records when record.types.indexOf('country') isnt -1
            deferred.reject()
        return deferred.promise()

    reportAnError: (message) ->
        @uNotify ||= new UNotify()
        @uNotify.content("#{message}.<br/>
Click <a href='https://github.com/openproxy/openproxy.github.io/wiki'>here<a/> for more information.")
        @uNotify.show() unless @uNotify.isShown()

    render: ->
        return unless window.google
        @$el.html($('#application-template').html()).find('a[title]').tipsy()
        map = constructMap(@$el.find('#map-container')[0])
        popover = new GoogleMapsPopover map: map
        mapClickListener = (event) =>
            map.panTo(event.latLng)
            popover.hide()
            @veil on
            @determineCountryByLatLng(event.latLng)
            .done (country) =>
                countryCode = country.address_components[0].short_name # expecting ISO_3166-1 here
                proxyListProvider = new XroxyProxyListProvider(countryCode: countryCode)
                proxyListProvider.fetch()
                .done (preloadedData) =>
                    popover.content @popoverTemplate(preloadedData)
                    @customizePopover?(popover)
                    $select = $(popover.el).find('.selectize')
                    $select.selectize
                        plugins: [
                            'select_on_preload'
                            {} = name: 'load_more', options: fetchSize: 10
                            'copy_to_clipboard'
                        ],
                        preload: true,
                        load: selectizeProxyListProvider(proxyListProvider, preloadedData)
                    @veil off
                    popover.show(country.geometry.location)
                .fail =>
                    @veil off
                    @reportAnError "Unable to retrieve list of proxies (from #{proxyListProvider.name})"
            .fail =>
                @veil off
        bindToClick map, mapClickListener
        marker = new google.maps.Marker map: map
        google.maps.event.addListener marker, 'click', mapClickListener
        geolocationProvider = new FreegeoipGeolocationProvider
        geolocationProvider.fetch()
        .done (geolocation) =>
            clientLatLng = new google.maps.LatLng(geolocation.latitude, geolocation.longitude)
            @determineCountryByLatLng(clientLatLng).done (country) ->
                marker.setPosition country.geometry.location
                map.panTo marker.getPosition()
        .fail =>
            @reportAnError("Unable to resolve current geolocation (using #{geolocationProvider.name})")

    popoverTemplate: (proxyList) ->
        result = ["<span class='google-maps-popover-arrow-up'></span>"]
        if proxyList.length
            result.push("<select id='proxy-list' class='selectize' style='width:100%;'/>")
        else
            result.push("<div style='text-align: center; margin-bottom: 3px'>No proxies in this location</div>")
        result.join('')

MicroPlugin.mixin(OpenProxy)

window.OpenProxy = OpenProxy