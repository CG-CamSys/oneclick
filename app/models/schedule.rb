class Schedule < ActiveRecord::Base
  include XmlSource

  #associations
  belongs_to :service

  attr_accessible :service, :service_id, :start_time, :end_time, :day_of_week

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :service_id
    super(options)
  end

end
