require 'spec_helper'

describe Admin::AgenciesController do
  include Devise::TestHelpers
  before (:all) do
    @agency = FactoryGirl.create(:arc_mobility_mgmt_agency)
    @admin_user = FactoryGirl.create(:admin)
    @regular_users = FactoryGirl.create_list(:user, 25)
    @agency_admins = FactoryGirl.create_list(:agency_admin, 1)
    @agents = FactoryGirl.create_list(:agency_agent, 10)
  end

  after(:all) do
    User.delete_all
  end

  describe "'travelers' action" do
    describe "for sys admin with no params" do #Sys Admins may not have access to this screen
      it "redirects" do
        login_as_using_find_by(email: @admin_user.email)
        pending "This seems to be a cancan issue"
        get :travelers, agency_id: 1 #doesn't matter the id, should always fail
        response.status.should eq 302
      end
    end
    describe "for agency staff" do
      before(:each) do
        login_as_using_find_by(email: @agency_admins.first.email)
        @agency = Agency.find_by(name: @agency.name)
        @usable = User.find_by(email: 'admin@example.com') #why isn't current_user getting pulled in from the devise helpers...?
      end
      describe "with no params" do
        it "returns only the travelers with existing AgencyUserRelationships with the current agency" do
          pending
          get :travelers, agency_id: @agency.id
          assigns(:pre_auth_travelers).count should eql(0)
          assigns(:found_travelers).count should eql(0)
          AgencyUserRelationship.new(:agency_id => @agency.id, user_id: 13, creator: @usable )
          get :travelers, :agency_id => @agency.id
          assigns(:pre_auth_travelers).count should eql(1)
          assigns(:found_travelers).count should eql(0)
        end
      end
      describe "with email param" do
        it "returns all travelers with existing AURs and any matching travelers" do
          pending
          AgencyUserRelationship.new(agency_id: @agency.id, user_id: 13, creator: @usable )
          get :travelers, agency_id: @agency.id, text: "email5@factory.com"
          assigns(:found_travelers).count should eql(1) #one with an AUR and one with matching email
          assigns(:pre_auth_travelers).count should eql(1)
        end
      end
    end
  end
  describe 'index' do
    it 'gets the index page successfully' do
      login_as_using_find_by(email: @agency_admins.first.email)
      get :index
      response.status.should eq 200
    end
  end
end