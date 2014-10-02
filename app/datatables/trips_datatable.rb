class TripsDatatable < AjaxDatatablesRails::Base
  # uncomment the appropriate paginator module,
  # depending on gems available in your project.
  # include AjaxDatatablesRails::Extensions::Kaminari
  # include AjaxDatatablesRails::Extensions::WillPaginate
  include AjaxDatatablesRails::Extensions::SimplePaginator

  def sortable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    if @sortable_columns.nil?
      @sortable_columns = ['trips.id', 'trips.created_at', 'users.first_name',
                           '', 'modes.name', 'trips.ui_mode',
                           '', '', '', '', '', '', '', '', '',
                           '', '', '', '', '', '', '', '', '',
                           'trip_purposes.name']
      if Oneclick::Application.config.allows_booking
        @sortable_columns.insert(16, '')
      end
    end
    @sortable_columns
  end

  def searchable_columns
    # list columns inside the Array in string dot notation.
    # Example: 'users.email'
    @searchable_columns ||=
      ['users.first_name', 'users.last_name', 'modes.name','trips.ui_mode', 'trip_purpose.name']
  end

  # These methods match the common reports_controller interface
  def get_columns
    cols = [:id, :created, :user, :assisted_by, :modes, :ui_mode,
            :leaving_from, :from_lat, :from_lon, :out_arrive_or_depart, :out_datetime,
            :going_to, :to_lat, :to_lon, :in_arrive_or_depart, :in_datetime,
            :round_trip, :eligibility, :accommodations, :outbound_itinerary_modes, :return_itinerary_modes,
            :status, :device, :location, :trip_purpose, :outbound_selected_short,
            :return_selected,]
    if Oneclick::Application.config.allows_booking
      cols.insert(16, :booked)
    end
    cols
  end

  def get_data(current_user, report)
    options[:dates] = DateOption.find(report.date_range)
    get_raw_records report.from_date, report.to_date
  end

  private

  def data
    cols = get_columns
    records.map do |record|
      record = record.decorate
      result = []
      cols.each do |col|
        result << record.send(col)
      end
      result
    end
  end

  def get_raw_records from_date=nil, to_date=nil
    from_date ||= options[:from_date]
    to_date ||= options[:to_date]
    
    Trip.includes(:user, :creator, :trip_places, :trip_purpose, :desired_modes, :trip_parts)
      .where(trip_parts: {scheduled_time: options[:dates].get_date_range(from_date, to_date)})
      .order('trip_places.sequence').order('trip_parts.sequence')
      .references(:user, :creator, :trip_places, :trip_purpose, :desired_modes, :trip_parts)
  end

  # ==== Insert 'presenter'-like methods below if necessary
end
