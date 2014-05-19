module Trip::ReturnTime
  extend ActiveSupport::Concern

  included do
    # For round trips. :return_trip_time is the time to start the return trip back the
    # start place
    attr_accessor :is_round_trip, :return_trip_time, :return_arrive_depart, :return_trip_date

    # ensure that a valid return time is set if a return trip is selected
    validate :validate_return_trip_time
  end

  # Returns the return trip date and time as a DateTime class. If the round-trip is not defined
  # we return nil
  def return_trip_datetime
    if is_round_trip != "1"
      return nil
    end

    begin
      return Chronic.parse([return_trip_date, return_trip_time].join(' '))
      # return DateTime.strptime([return_trip_date, return_trip_time, DateTime.current.zone].join(' '), '%m/%d/%Y %H:%M %p %z')
    rescue Exception => e
      Rails.logger.warn "return_trip_datetime #{trip_date} #{trip_time}"
      Rails.logger.warn e.message
      return nil
    end
  end

  def self.defaults trip
    travel_date = if respond_to?(:trip_time) && trip_time.present?
      trip_time
    else
      TripsSupport.default_trip_time
    end

    # default to a round trip. The default return trip time is set the the default trip time plus
    # a configurable interval
    return_trip_time = travel_date + TripsSupport::DEFAULT_RETURN_TRIP_DELAY_MINS.minutes
    trip.is_round_trip = "1"
    trip.return_trip_time = return_trip_time.strftime(TripsSupport::TRIP_TIME_FORMAT_STRING)
    trip
  end

protected

  # Validation. Check that the return trip time is well formatted and after the trip time
  def validate_return_trip_time
    return_dt = return_trip_datetime
    if return_dt && (return_dt <= trip_datetime)
      errors.add(:return_trip_time, I18n.translate(:return_trip_time_before_start))
    end
  end

end
