class Provider < ActiveRecord::Base
  include XmlSource

  #associations
  has_many :services
  attr_accessible :name, :contact, :external_id

end
