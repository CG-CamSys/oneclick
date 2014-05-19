# TODO There's a lot of duplication between this and trips.js.coffee

create_or_update_marker = (map, key, lat, lon, name, desc, iconStyle) ->  
  marker = map.findMarkerById(key)
  map.removeMarkerFromMap marker  if marker
  marker = map.createMarker(key, lat, lon, iconStyle, desc, name, true)
  map.addMarkerToMap marker, true
  marker

update_map = (map, type, e, s, d) ->
  lat = s.lat
  lon = s.lon
  if lat==null
    $.ajax
      type: 'GET'
      url: '/place_details/' + s.id
      async: false
      success: (data) ->
        lat = data.result.geometry.location.lat
        lon = data.result.geometry.location.lng
  key = 'start'
  icon = 'startIcon'
  map.removeMatchingMarkers(key);
  marker = create_or_update_marker(map, key, lat, lon, s.name, s.full_address, icon);
  map.setMapToBounds();
  map.selectMarker(marker);

$ ->
  $('#places-table tr').on 'click', (e) ->
    $('#places-table tr').removeClass('success')
    tr = $(e.target).closest('tr')
    dataset = $(tr).data()
    tr.addClass('success')
    $('#places_controller_places_proxy_from_place').val(dataset.address)
    $('#places_controller_places_proxy_json').val(JSON.stringify(dataset.json))
    $('#places_controller_places_proxy_place_name').val(dataset.placename)

  $('#clear').on 'click', () ->
    $('#places_controller_places_proxy_from_place').val('')
    $('#places_controller_places_proxy_json').val('')
    $('#places_controller_places_proxy_place_name').val('')

  places = new Bloodhound
    datumTokenizer: (d) ->
      Bloodhound.tokenizers.whitespace(d.value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    remote:
      url: '/place_search.json?no_map_partial=true'
      rateLimitWait: 600
      replace: (url, query) ->
        url = url + '&query=' + query
        url = url + '&map_center=33.7550,-84.3900'
        return url
    limit: 20
    # prefetch: '../data/films/post_1960.json'

  places.initialize()

  $(".places .place_picker").typeahead null,
    limit: 20,
    displayKey: "name"
    source: places.ttAdapter()
    templates:
      suggestion: Handlebars.compile([
        '<a>{{name}}</a>'
      ].join(''))
  
  $('#places_controller_places_proxy_from_place').on 'typeahead:selected', (e, s, d) ->
    $('#places_controller_places_proxy_json').val(JSON.stringify(s))
    update_map(CsMaps.placesMap, 'trip', e, s, d)
  $('#places_controller_places_proxy_from_place').on 'typeahead:autocompleted', (e, s, d) ->
    $('#places_controller_places_proxy_json').val(JSON.stringify(s))
    update_map(CsMaps.placesMap, 'trip', e, s, d)
