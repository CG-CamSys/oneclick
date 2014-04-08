class GeocodedAddress < ActiveRecord::Base
  include InterestingAttributes
  
  self.abstract_class = true  
  
  # # attr_accessible :address1, :address2, :city, :state, :zip
  # # attr_accessible :lat, :lon
  # # attr_accessible :county

  def get_zipcode
    return zip
  end
  
  def get_location
    return [lat, lon]
  end

  def get_county_name
    return county
  end

  def get_address
    # a1, [a2, ]city, state zip
    [[address1, address2].reject{|a| a.blank?}.join(', '),
    city,
    [state, zip].join(' ')].join(', ')
  end
  
end