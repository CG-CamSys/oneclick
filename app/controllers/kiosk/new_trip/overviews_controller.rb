class Kiosk::NewTrip::OverviewsController < Kiosk::NewTrip::BaseController
  def create
    # inflate a trip proxy object from the form params
    params[:trip_proxy].delete(:trip_purpose)
    @trip_proxy = create_trip_proxy_from_form_params

    if @trip_proxy.valid?
      @trip = create_trip(@trip_proxy)
    else
      raise @trip_proxy.errors.as_json.inspect
    end

    # Create markers for the map control
    @markers = create_trip_proxy_markers(@trip_proxy).to_json
    @places = create_place_markers(@traveler.places)

    if @trip.save
      @trip.cache_trip_places_georaw
      @trip.reload

      # @trip.restore_trip_places_georaw
      if @traveler.user_profile.has_characteristics? && user_signed_in?
        @trip.create_itineraries
        @path = user_trip_path_for_ui_mode(@traveler, @trip)
      else
        session[:current_trip_id] = @trip.id
        @path = new_user_characteristic_path_for_ui_mode(@traveler, inline: 1)
      end

      render json: {
        location: @path,
        trip: {}
      }
    else
      render json: @trip_proxy, status: :unprocessable_entity
    end
  end
end
