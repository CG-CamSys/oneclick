class Provider < ActiveRecord::Base
  include XmlSource

  #associations
  has_many :services
  attr_accessible :name, :contact, :external_id, :url

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :provider_id
    super(options)
  end

end
