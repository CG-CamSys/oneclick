class TravelerAccommodation < ActiveRecord::Base
  include XmlSource
  
  attr_accessible :id, :code, :name, :note, :datatype, :active

  has_many :user_traveler_accommodations_maps
  has_many :user_profiles, through: :user_traveler_accommodations_maps

  has_many :service_traveler_accommodations_maps, foreign_key: :accommodation_id
  has_many :services, through: :service_traveler_accommodations_maps

  # set the default scope
  default_scope where('traveler_accommodations.active = ?', true)

end
