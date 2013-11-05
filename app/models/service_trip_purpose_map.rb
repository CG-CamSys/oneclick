class ServiceTripPurposeMap < ActiveRecord::Base
  include XmlSource
  
  #associations
  belongs_to :service
  belongs_to :trip_purpose

  attr_accessible :id, :service_id, :service, :trip_purpose_id, :trip_purpose, :value, :active, :value_relationship_id

end
