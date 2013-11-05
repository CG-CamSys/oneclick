class GeoCoverage < ActiveRecord::Base
  include XmlSource
  
  #associations
  has_many :service_coverage_maps
  has_many :services, through: :service_coverage_maps

  attr_accessible :coverage_type, :value

end
