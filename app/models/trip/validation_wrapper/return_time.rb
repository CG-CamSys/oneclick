class Trip::ValidationWrapper::ReturnTime < Trip::ValidationWrapper::Base
  include Trip::ReturnTime
  attr_accessor :trip_time

  def as_json val
    if is_round_trip != '1'
      @return_trip_time = nil
    end

    super
  end
end
