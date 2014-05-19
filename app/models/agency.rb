class Agency < ActiveRecord::Base
  resourcify

  belongs_to :parent, class_name: 'Agency'
  has_many :sub_agencies, -> {order('name')}, class_name: 'Agency', foreign_key: :parent_id
  has_many :users
  accepts_nested_attributes_for :users
  has_many :agency_user_relationships
  has_many :approved_agency_user_relationships,-> { where(relationship_status: RelationshipStatus.confirmed) }, class_name: 'AgencyUserRelationship'
  has_many :customers, :class_name => 'User', :through => :approved_agency_user_relationships, source: :user
  # has_many :cs_roles, -> {where(resource_type: 'Agency')}, class_name: 'Role'
  has_many :cs_roles, -> {where(resource_type: 'Agency')}, class_name: 'Role', foreign_key: :resource_id
  has_many :cs_users, class_name: 'User', through: :cs_roles, source: :users
  has_many :agents, -> {where('roles.name=?', 'agent')}, class_name: 'User', through: :cs_roles, source: :users
  has_many :administrators, -> {where('roles.name=?', 'agency_administrator')}, class_name: 'User', through: :cs_roles, source: :users

  validates :name, :presence => true
  
  def unselected_users
    User.registered - self.users
  end

  def possible_parents
    Agency.all - [self]
  end

  def name_and_id
    [name, id]
  end

  def self.names_and_ids
    Agency.all.map(&:name_and_id)
  end

  def internal_contact
    users.with_role( :internal_contact, self).first
  end

  def internal_contact=(user)
    self.internal_contact.remove_role( :internal_contact, self) if self.internal_contact.present?
    user.add_role(:internal_contact, self)
  end

  def agency_id
    id
  end

end
