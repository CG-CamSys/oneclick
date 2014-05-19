class Characteristic < ActiveRecord::Base
  include EligibilityOperators

  # attr_accessible :id, :code, :name, :note, :datatype, :active, :characteristic_type, :desc, :sequence

  has_many :user_characteristics
  has_many :user_profiles, through: :user_characteristics

  has_many :service_characteristics
  has_many :services, through: :service_characteristics

  # set the default scope
  default_scope {where('characteristics.active = ?', true)}
  scope :active, -> {where(active: true)}
  scope :enabled, -> {where('datatype != ?', 'disabled')}
  scope :personal_factors, -> {where('characteristic_type = ?', 'personal_factor')}
  scope :programs, -> {where('characteristic_type = ?', 'program')}
  scope :enabled, -> { where.not(datatype: 'disabled') }

  # builds a hash of details about a characteristic; is used by the javascript
  # client to knwo whether to ask the user for more info
  def for_missing_info(service, group)
    a = attributes
    sc = service_characteristics.where(service: service).take
    value = case a['code']
    when 'age'
      Date.today.year - sc.value.to_i
    else
      sc.value
    end
    operator = case a['code']
    when 'age'
      reverse_relationship_to_symbol(sc.value_relationship_id)
    else
      relationship_to_symbol(sc.value_relationship_id)
    end
    options = a['datatype']=='bool' ? [{text: I18n.t(:yes_str), value: true}, {text: I18n.t(:no_str), value: false}] : nil
    {
      'question' => I18n.t(a['note']),
      #'description' => I18n.t(a['desc']),
      'data_type' => a['datatype'],
      # 'control_type' => '',
      'options' => options,
      'success_condition' => "#{operator}#{value}",
      'group_id' => group
    }
  end

end
