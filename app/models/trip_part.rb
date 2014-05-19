class TripPart < ActiveRecord::Base

  #associations
  belongs_to :trip
  belongs_to :from_trip_place,  :class_name => "TripPlace", :foreign_key => "from_trip_place_id"
  belongs_to :to_trip_place,    :class_name => "TripPlace", :foreign_key => "to_trip_place_id"

  has_many :itineraries

  # Ordering of trip parts within a trip. 0 based
  # attr_accessible :sequence
  # date and time that the trip part is scheduled for stored as a string
  # attr_accessible :scheduled_date, :scheduled_time, :from_trip_place, :to_trip_place


  # true if the trip_time refers to the deaperture time at the origin. False
  # if it is arrival at the destination
  # attr_accessible :is_depart
  # true if the trip part is the return trip
  # attr_accessible :is_return_trip

  validates :from_trip_place, presence: true
  validates :to_trip_place, presence: true

  # Scopes
  scope :created_between, lambda {|from_time, to_time| where("trip_parts.created_at > ? AND trip_parts.created_at < ?", from_time, to_time).order("trip_parts.trip_time DESC") }
  #scope :scheduled_between, lambda {|from_time, to_time| where("trip_parts.trip_time > ? AND trip_parts.trip_time < ?", from_time, to_time).order("trip_parts.trip_time DESC") }

  def has_hidden_options?
    itineraries.valid.hidden.count > 0
  end

  def is_return_trip?
    is_return_trip
  end

  # We define that an itinerary has been selected if there is exactly 1 visible valid one.
  # We might want a more explicit selection flag in the future.
  def selected?
    itineraries.valid.selected.count == 1
  end

  # Returns the itinerary selected for this trip.  If one isn't selected, returns nil
  def selected_itinerary
    if selected?
      return itineraries.valid.selected.first
    else
      return nil
    end
  end

  # Converts the trip date and time into a date time object
  def trip_time
    # puts scheduled_date.ai
    # puts scheduled_time.ai
    # DateTime.new(scheduled_date.year, scheduled_date.month, scheduled_date.day,
    #   scheduled_time.hour, scheduled_time.min, 0, scheduled_time.offset)
    scheduled_time
  end

  # Returns an array of TripPart that have at least one valid itinerary but all
  # of them have been hidden by the user
  def self.rejected
    joins(:itineraries).where('server_status=200 AND hidden=true')
  end

  # Returns an array of TripPart where no valid options were generated
  def self.failed
    joins(:itineraries).where('server_status <> 200')
  end

  # returns true if the trip part is scheduled in advance of
  # the current or passed in date
  def in_the_future(now=Time.now)
    trip_time > now
  end

  def remove_existing_itineraries
    itineraries.destroy_all
  end

  # Generates itineraries for this trip part. Any existing itineraries should have been removed
  # before this method is called.
  def create_itineraries
    remove_existing_itineraries
    timed "fixed" do
      create_fixed_route_itineraries if trip.desired_modes.include? Mode.transit
    end
    timed "taxi" do
      create_taxi_itineraries if trip.desired_modes.include? Mode.taxi
    end
    timed "paratransit" do
      create_paratransit_itineraries if trip.desired_modes.include? Mode.paratransit
    end
    timed "rideshare" do
      create_rideshare_itineraries if trip.desired_modes.include? Mode.rideshare
    end
  end

  def timed label, &block
    s = Time.now
    yield block
    s2 = Time.now
    Rails.logger.info "TIMING: #{label} #{s2 - s} #{s} #{s2}"
  end

  # TODO refactor following 4 methods
  def create_fixed_route_itineraries(mode="TRANSIT,WALK")
    tp = TripPlanner.new
    arrive_by = !is_depart
    result, response = tp.get_fixed_itineraries([from_trip_place.location.first, from_trip_place.location.last],[to_trip_place.location.first, to_trip_place.location.last], trip_time, arrive_by.to_s, mode)

    #TODO: Save errored results to an event log
    if result
      tp.convert_itineraries(response).each do |itinerary|
        serialized_itinerary = {}

        itinerary.each do |k,v|
          if v.is_a? Array
            serialized_itinerary[k] = v.to_yaml
          else
            serialized_itinerary[k] = v
          end
        end

        itineraries << Itinerary.new(serialized_itinerary)
      end
    end

    if mode == 'TRANSIT,WALK' and result
      check_for_long_walks(itineraries)
    end

    # Don't hide duplicate itineraries in new UI
    # See https://www.pivotaltracker.com/story/show/71254872
    # TODO This will probably break kiosk, will add story
    # hide_duplicate_fixed_route(itineraries)

  end

  def check_for_long_walks itineraries
    long_walks = false
    itineraries.each do |itinerary|
      first_leg = itinerary.get_legs.first
      #TODO: Make the 20 minute threshold configurable.
      if first_leg.mode == 'WALK' and first_leg.duration > 1200
        long_walks = true
        itinerary.hide
      end
    end
    if long_walks
      create_fixed_route_itineraries('CAR,TRANSIT,WALK')
    end
  end

  # Note not called for now.
  # See https://www.pivotaltracker.com/story/show/71254872
  def hide_duplicate_fixed_route itineraries
    seen = {}
    itineraries.each do |i|
      if i.mode.nil?
        Rails.logger.info "hide_duplicate_fixed_route"
        Rails.logger.info "Skipping itinerary because mode is nil: #{i.ai}"
        next
      end
      mar = i.mode_and_routes
      i.hide if seen[mar]
      seen[mar] = true
    end
  end

  def create_taxi_itineraries
    tp = TripPlanner.new
    result, response = tp.get_taxi_itineraries([from_trip_place.location.first, from_trip_place.location.last],[to_trip_place.location.first, to_trip_place.location.last], trip_time)
    if result
      itinerary = tp.convert_taxi_itineraries(response)
      itinerary['server_message'] = itinerary['server_message'].to_yaml if itinerary['server_message'].is_a? Array
      self.itineraries << Itinerary.new(itinerary)
    else
      self.itineraries << Itinerary.new('server_status'=>500, 'server_message'=>response.to_s)
    end
  end

  def create_paratransit_itineraries
    eh = EligibilityService.new
    fh = FareHelper.new
    itineraries = eh.get_accommodating_and_eligible_services_for_traveler(self)
    itineraries = eh.get_eligible_services_for_trip(self, itineraries)

    itineraries = itineraries.collect do |itinerary|
      new_itinerary = Itinerary.new(itinerary)
      fh.calculate_fare(new_itinerary)
      new_itinerary
    end

    unless itineraries.empty?
      unless ENV['SKIP_DYNAMIC_PARATRANSIT_DURATION']
        begin
          tp = TripPlanner.new
          arrive_by = !is_depart
          result, response = tp.get_fixed_itineraries([from_trip_place.location.first, from_trip_place.location.last],
                                                      [to_trip_place.location.first, to_trip_place.location.last], trip_time, arrive_by.to_s, 'CAR')
          base_duration = response['itineraries'].first['duration'] / 1000.0
        rescue Exception => e
          Rails.logger.error "Exception #{e} while getting trip duration."
          base_duration = nil
        end
      else
        Rails.logger.info "SKIP_DYNAMIC_PARATRANSIT_DURATION is set, skipping it"
      end
      Rails.logger.info "Base duration: #{base_duration} minutes"
      itineraries.each do |i|
        i.duration_estimated = true
        if base_duration.nil?
          i.duration = Oneclick::Application.config.minimum_paratransit_duration
        else
          i.duration =
            [base_duration * Oneclick::Application.config.duration_factor,
             Oneclick::Application.config.minimum_paratransit_duration].max
        end
        Rails.logger.info "Factored duration: #{i.duration} minutes"
        if is_depart
          i.start_time = trip_time
          i.end_time = i.start_time + i.duration
        else
          i.end_time = trip_time
          i.start_time = i.end_time - i.duration
        end
        Rails.logger.info "AFTER"
        Rails.logger.info i.duration.ai
        Rails.logger.info i.start_time.ai
        Rails.logger.info i.end_time.ai
      end
    end

    self.itineraries += itineraries

  end

  def create_rideshare_itineraries
    tp = TripPlanner.new
    trip.restore_trip_places_georaw
    result, response = tp.get_rideshare_itineraries(from_trip_place, to_trip_place, trip_time)
    if result
      itinerary = tp.convert_rideshare_itineraries(response)
      self.itineraries << Itinerary.new(itinerary)
    else
      self.itineraries << Itinerary.new('server_status'=>500, 'server_message'=>response.to_s,
                                        'mode' => Mode.rideshare)
    end
  end

  def max_notes_count
    itineraries.valid.visible.map(&:notes_count).max
  end

end
