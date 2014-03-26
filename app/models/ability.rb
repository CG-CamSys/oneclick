class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.has_role?(:admin) or user.has_role?(:system_administrator)
      # admin users can do anything      
      can :manage, :all

      # TODO Are these 2 redundant?
      can [:see], :admin_menu
      can [:index], :admin_home

      # TODO Can this whole block be done more efficiently?
      can [:access], :admin_find_traveler
      can [:access], :admin_create_traveler
      can [:access], :admin_trips
      can [:access], :admin_agencies
      can [:access], :admin_users
      can [:access], :admin_providers
      can [:access], :admin_services
      can [:access], :admin_reports
      can [:access], :admin_feedback
      # can :manage_travelers, Agency #Turned off for now.
      return
    end
    if User.with_role(:agency_administrator, :any).include?(user)
      # TODO Are these 2 redundant?
      can [:see], :admin_menu
      can [:index], :admin_home

      can [:access], :admin_find_traveler
      can [:access], :admin_create_traveler
      can [:access], :admin_trips
      can [:access], :admin_agencies
      can [:access], :admin_users
      can [:access], :admin_providers
      can [:access], :admin_services
      can [:access], :admin_reports
      can [:access], :admin_feedback

      can :manage, AgencyUserRelationship, agency_id: user.agency.try(:id)
      can :manage, Agency, id: user.agency.try(:id)
      can :manage_travelers, Agency
      can :perform, :assist_user
      can :create, User
      can :manage, [ProviderOrg, Service]
      can [:index, :show], :reports
      can [:read, :update], User, {agency_id: user.agency.try(:id)}
    end
    if User.with_role(:agent, :any).include?(user)
      can [:see], :admin_menu
      can [:index], :admin_home
      can [:access], :admin_find_traveler
      can [:access], :admin_create_traveler
      can [:access], :admin_trips
      can [:access], :admin_providers
      can [:access], :admin_services
      can [:access], :admin_reports
      can [:access], :admin_feedback
      can [:index, :show], :reports
      can [:index, :show], [ProviderOrg, Service]
      can :manage_travelers, :agency
      can :perform, :assist_user
      can :create, User
    end

    if User.with_role(:provider_staff, :any).include?(user)
      can [:see], :admin_menu
      can [:index], :admin_home

      can [:access], :admin_trips
      can [:access], :admin_providers
      can [:access], :admin_services
      can [:access], :admin_reports
      can [:access], :admin_feedback

      can [:index, :show], :reports
      can [:manage], ProviderOrg, id: user.try(:provider_org_id)
      # can [:manage], Service
    end

    can [:read, :create, :update, :destroy], [Trip, Place], :user_id => user.id 
    #can :manage, BuddyRelationship, :user_id => user.id
    can [:read, :update], User, :id => user.id
    can :geocode, :util
  end

end

# :admin_find_traveler
# :admin_create_traveler
# :admin_trips
# :admin_agencies
# :admin_users
# :admin_providers
# :admin_services
# :admin_reports

    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
