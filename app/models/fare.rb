class Fare < ActiveRecord::Base
  include XmlSource

  attr_accessible :amount, :base_cost, :base_units, :description, :fare_type, :unit, :voluntary
  validates :fare_type, presence: true
  validates :description, presence: true

  belongs_to :service

  TYPE_FLAT = 'flat'
  TYPE_MILEAGE = 'mileage'
  TYPE_CONTACT = 'contact'
  TYPE_COMPLEX = 'complex'
  UNIT_MILES = 'miles'

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] += [:created_at, :updated_at, :id, :service_id, :base_cost, :base_units]
    options[:except] << :unit if unit.nil?
    options[:except] << :voluntary if voluntary.nil?
    super(options) do |b|
      unless base_cost.nil?
        b.base do |b|
          b.cost base_cost
          b.units base_units
        end
      end
    end
  end

end
