###
Slimmed down version of
<a href="http://google-maps-utility-library-v3.googlecode.com/svn/trunk/infobox">InfoBox</a>
(Copyright 2010 Gary Little, licensed under the Apache License, Version 2.0).
This one has no IE suppport.
###

class GoogleMapsPopover extends google.maps.OverlayView

    constructor: (options) ->
        @_el = $("<div class='google-maps-popover' style='display: none'></div>")[0]
        @_margin = x: options.marginByX or 4, y: options.marginByY or 4
        @content options.content if options.content
        @setMap options.map or throw new Error '"map" is required'

    # required by google.maps.OverlayView
    onAdd: ->
        stopPropagationListener = (e) ->
            e.stopPropagation()
        google.maps.event.addDomListener(@_el, eventType, stopPropagationListener) for eventType in [
            'mousedown', 'mouseover', 'mouseout', 'mouseup', 'click', 'dblclick', 'touchstart', 'touchend', 'touchmove']
        google.maps.event.addDomListener(@_el, 'contextmenu', -> return false)
        google.maps.event.addDomListener(@_el, 'mouseover', -> @style.cursor = 'default')
        @getPanes()['floatPane'].appendChild @_el

    # required by google.maps.OverlayView
    draw: ->
        return unless @_visible
        $('.gm-style').removeClass('gm-style') # todo: move outside of GoogleMapsPopover
        position = @getProjection().fromLatLngToDivPixel(@_position)
        computedStyle = @_el.ownerDocument.defaultView.getComputedStyle(@_el, null)
        width = parseInt(computedStyle.getPropertyValue('width'), 10)
        unless isNaN(width)
            position.x -= width / 2
        @_el.style.position = 'absolute'
        @_el.style.left = position.x + 'px'
        @_el.style.top = position.y + 'px'
        @_el.style.display = if @_visible then 'block' else 'none'

    # required by google.maps.OverlayView
    onRemove: ->
        return unless @_el
        @_el.parentNode.removeChild @_el
        @_el = null

    show: (anchor)->
        if anchor instanceof google.maps.Marker
            @_position = anchor.getPosition()
        else if anchor instanceof google.maps.LatLng
            @_position = anchor
        @_visible = true
        @draw()
        @moveIntoViewport()

    moveIntoViewport: ->
        $el = $(@_el)
        width = parseInt($el.outerWidth(true), 10)
        height = parseInt($el.outerHeight(true), 10)
        mapDiv = @getMap().getDiv()
        [mapWidth, mapHeight] = [mapDiv.offsetWidth, mapDiv.offsetHeight]
        [marginByX, marginByY] = [@_margin.x, @_margin.y]
        [offsetByX, offsetByY] = [0, 0]
        halfOfTheWidth = width / 2
        markerPosition = @getProjection().fromLatLngToContainerPixel(@_position)
        if markerPosition.x < marginByX + halfOfTheWidth # obscured to the left
            offsetByX = markerPosition.x - marginByX - halfOfTheWidth
        else if markerPosition.x + halfOfTheWidth + marginByX > mapWidth # obscured to the right
            offsetByX = markerPosition.x + halfOfTheWidth + marginByX - mapWidth
        if markerPosition.y + height + marginByY > mapHeight # obscured at the bottom
            offsetByY = markerPosition.y + height + marginByY - mapHeight
        unless offsetByX is 0 and offsetByY is 0
            @getMap().panBy offsetByX, offsetByY

    content: (content)->
        $(@_el).html(content)
        return @

    hide: ->
        @_visible = false
        @_el.style.display = 'none'

    destroy: ->
        google.maps.event.clearInstanceListeners @_el
        @setMap null
