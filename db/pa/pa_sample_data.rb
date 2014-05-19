#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) are set in the file config/application.yml.
# See http://railsapps.github.io/rails-environment-variables.html

def add_users_and_places
  places = [
    {active: 1, name: 'My house', raw_address: '100 Dewey Street, West York, PA, 17404'},
    {active: 1, name: 'VA York Clinic', raw_address: '2251 Eastern Blvd, York, PA 17402'},
    {active: 1, name: "YMCA Men's Emergency Shelter", raw_address: '310 West Philadelphia Street, York, PA, 17401'}
    ]
  users = [
    {first_name: 'Denis', last_name: 'Haskin', email: 'dhaskin@camsys.com'},
    {first_name: 'Derek', last_name: 'Edwards', email: 'dedwards@camsys.com'},
    {first_name: 'Eric', last_name: 'Ziering', email: 'eziering@camsys.com'},
    {first_name: 'Galina', last_name: 'Dymkova', email: 'gdymkova@camsys.com'},
    {first_name: 'Aaron', last_name: 'Magil', email: 'amagil@camsys.com'},
    {first_name: 'Julian', last_name: 'Ray', email: 'jray@camsys.com'},
    {first_name: 'Scott', last_name: 'Meeks', email: 'smeeks@camsys.com'},
    {first_name: 'Test', last_name: 'Customer', email: 'ecolane@camsys.com'}
  ]

  users.each do |user|
    puts "Add/replace user #{user[:email]}"

    u = User.find_by_email(user[:email])
    unless u.nil?
      next
    end

    u = User.create! user.merge({password: 'welcome1'})
    up = UserProfile.new
    up.user = u
    up.save!
    places.each do |place|
      p = Place.new(place)
      p.creator = u
      p.geocode
      u.places << p
      begin
        u.save!
      rescue Exception => e
        puts e.inspect
        puts u.errors.inspect
        u.places.each do |pl|
          puts pl.errors.inspect
        end
      end
    end
    Mode.all.each do |mode|
      ump = UserModePreference.new
      ump.user = u
      ump.mode = mode
      ump.save!
    end
    u.add_role :registered_traveler    
  end
end

##### Eligibility Seeds #####

#Traveler characteristics
def add_providers_and_services
  disabled = Characteristic.find_by_code('disabled')
  matp = Characteristic.find_by_code('matp')
  #nemt_eligible = Characteristic.find_by_code('nemt_eligible')
  ada_eligible = Characteristic.find_by_code('ada_eligible')
  veteran = Characteristic.find_by_code('veteran')
  #low_income = Characteristic.find_by_code('low_income')
  date_of_birth = Characteristic.find_by_code('date_of_birth')
  age = Characteristic.find_by_code('age')
  walk_distance = Characteristic.find_by_code('walk_distance')

  #Traveler accommodations
  folding_wheelchair_accessible = Accommodation.find_by_code('folding_wheelchair_accessible')
  motorized_wheelchair_accessible = Accommodation.find_by_code('motorized_wheelchair_accessible')
  lift_equipped = Accommodation.find_by_code('lift_equipped')
  #door_to_door = Accommodation.find_by_code('door_to_door')
  curb_to_curb = Accommodation.find_by_code('curb_to_curb')
  #driver_assistance_available = Accommodation.find_by_code('driver_assistance_available')

  #Service types
  paratransit = ServiceType.find_by_code('paratransit')
  volunteer = ServiceType.find_by_code('volunteer')
  #nemt = ServiceType.find_by_code('nemt')

  #trip_purposes
  work = TripPurpose.find_by_code('work')
  training = TripPurpose.find_by_code('training_employment')
  medical = TripPurpose.find_by_code('medical')
  dialysis = TripPurpose.find_by_code('dialysis')
  cancer = TripPurpose.find_by_code('cancer_treatment')
  personal = TripPurpose.find_by_code('personal_errand')
  general = TripPurpose.find_by_code('general_purpose')
  senior = TripPurpose.find_by_code('senior_center')
  grocery = TripPurpose.find_by_code('grocery')

  providers = [
      {name: 'Rabbit Transit', contact: "rabbit contact",
       address: '1230 Roosevelt Ave.', city: 'York', state: 'PA', zip: '17404',
       phone: '717-846-RIDE', email: 'info@rabbittransit.org',
       url: 'http://www.rabbittransit.org/', external_id: "1"},
      {name: 'Faith in Action Network', contact: 'test name', external_id: "2"},
      {name: 'American Cancer Society', contact: 'acs name', external_id: "3"},
      {name: 'Lutheran Social Services', contact: 'lss name', external_id: "4"},
      {name: 'York County Area Agency on Aging', contact: 'temp name', external_id:  "5"}

  ]

  #Create providers and services with custom schedules, eligibility, and accommodations
  providers.each do |provider|
    puts "Add/replace provider #{provider[:external_id]}"

    p = Provider.find_by_external_id(provider[:external_id])
    unless p.nil?
      next
    end

    contact = provider.delete(:contact)
    (first_name, last_name) = contact.split(/ /, 2)
    p = Provider.create! provider
    p.save

    puts contact.downcase.gsub(' ', '_').gsub(%r{\W}, '') + '@camsys.com'
    u = User.create! first_name: first_name, last_name: last_name,
        email: contact.downcase.gsub(' ', '_').gsub(%r{\W}, '') + '@camsys.com', password: 'welcome1'
    up = UserProfile.create! user: u
    # p.users << u
    u.add_role :internal_contact, p


    case p.external_id

      when "2" #Faith in Action Network

        service = Service.create(name: 'Staying Connected', provider: p, service_type: paratransit, advanced_notice_minutes: 7*24*60)
        #Add Schedules
        (1..4).each do |n|
          Schedule.create(service: service, start_seconds:9*3600, end_seconds:16*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        # was: 
        # [medical, grocery, cancer, general].each do |n|
        #   ServiceTripPurposeMap.create(service: service, trip_purpose: n)
        # end

        #Add geographic restrictions
        ['York'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Add geographic restrictions
        ['York'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service,characteristic: age, value: '60', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [curb_to_curb, folding_wheelchair_accessible].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n)
        end

      when "3" #American Cancer Society

        service = Service.create(name: 'Road to Recovery Program', provider: p, service_type: paratransit, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 16.5*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n)
        end

        #Add geographic restrictions
        ['York', 'Adams'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Add geographic restrictions
        ['York', 'Adams'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end


        #Traveler Accommodations Requirements
        [curb_to_curb, folding_wheelchair_accessible].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n)
        end

      when "4" #Luthern Social Services of South Central PA

        service = Service.create(name: 'Touch a Life', provider: p, service_type: paratransit, advanced_notice_minutes: 5*24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 16.5*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        # was: 
        # [cancer, medical, general, grocery].each do |n|
        #   ServiceTripPurposeMap.create(service: service, trip_purpose: n)
        # end

        #Add geographic restrictions
        ['York', 'Adams', 'Franklin', 'Fulton'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Add geographic restrictions
        ['York', 'Adams', 'Franklin', 'Fulton'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end


        #Traveler Accommodations Requirements
        [curb_to_curb, folding_wheelchair_accessible].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n)
        end

      when "5" #Area Agency on Aging

        service = Service.create(name: 'Area Agency on Aging', provider: p, service_type: paratransit, advanced_notice_minutes: 5*24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8*3600, end_seconds: 16.5*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        # was: 
        # [cancer, medical, general, grocery].each do |n|
        #   ServiceTripPurposeMap.create(service: service, trip_purpose: n)
        # end

        #Add geographic restrictions
        ['York', 'Adams', 'Franklin', 'Fulton'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Add geographic restrictions
        ['York', 'Adams', 'Franklin', 'Fulton'].each do |z|
          c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Characteristics Required
        ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [curb_to_curb, folding_wheelchair_accessible].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n)
        end
    end
  end
end

def add_fares
  service = Service.find_by_name('Senior Shared Ride')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "For Senior Center, Medical, Pharmacy, Dialysis or Adult Day Care:<br>Zone 1: $1.50, Zone 2: $3.00, Zone 3: $3.50, Zone 4: $4.50.<br><br> Other Trips:<br>Zone 1: $2.35, Zone 2: $3.30, Zone 3: $4.60, Zone 4: $6.65")
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Shared Ride for Ages 60-64')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "For MA Eligible and going to Senior Center or Adult Day Care:<br>Zone 1: $1.50, Zone 2: $6.50, Zone 3: $7.00, Zone 4: $8.25.<br><br>   Other Trips: <br>Zone 1: $15.65, Zone 2: $22.00, Zone 3: $30.50, Zone 4: $44.25")
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Medical Assistance Transportation Program')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('ADA Complementary Service')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "Zone 1: $3.10, Zone 2: $4.00")
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Service for Persons with Disabilities')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc:  "Zone 1: $2.35, Zone 2: $3.30, Zone 3: $4.60, Zone 4: $6.65")
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Staying Connected')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "Registration is required with an annual $60.00 administration fee.")
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Road to Recovery Program')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Touch a Life')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

  service = Service.find_by_name('Area Agency on Aging')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    unless service.nil?
      puts "Fare already exists for " + service.name
    end
  end

end

def add_dav
  if Provider.find_by_name('Veterans Affairs').nil?

    lebanon = TripPurpose.find_by_code('visit_lebanon_va_medical_center')

    provider = {name: 'Veterans Affairs', contact: 'DAV Contact', external_id:  "6"}


    contact = provider.delete(:contact)
    (first_name, last_name) = contact.split(/ /, 2)
    p = Provider.create! provider
    p.save

    puts contact.downcase.gsub(' ', '_').gsub(%r{\W}, '') + '@camsys.com'
    u = User.create! first_name: first_name, last_name: last_name,
        email: contact.downcase.gsub(' ', '_').gsub(%r{\W}, '') + '@camsys.com', password: 'welcome1'
    up = UserProfile.create! user: u
    # p.users << u
    u.add_role :internal_contact, p

    #Create service Disabled American Vets van
    paratransit = ServiceType.find_by_code('paratransit')
    service = Service.create(name: 'Disabled American Veterans: Van to Lebanon VA', provider: p, service_type: paratransit, advanced_notice_minutes: 5*24*60)
    #Add Schedules
    (1..5).each do |n|
      Schedule.create(service: service, start_seconds: 3600*13, end_seconds: 17*3600, day_of_week: n)
    end

    FareStructure.create(service: service, fare_type: 0, base: 0.00, desc: 'The Transportation Van is a VOLUNTEERED shuttle that runs from York Out Patient Clinic to Lebanon Hospital. The van is a 7-8 passenger van and operates Monday thru Friday 8:00 AM-12:00 PM. The van leaves normally one hour and a half to an hour and fifteen minutes prior to the first appointment (i.e. appt in Lebanon is at 8:00A.M. departure time is 6:45 AM) and leaves Lebanon VA to come back to York at 12:00 PM. Any appointments after 11:30 AM, is the Patients responsibility to obtain return transportation to York. The DRIVER is NOT responsible for patients return trip to York if appointment runs past 12:00 P.M.<br>
  When scheduling appointment(s), patients must inform the scheduling clerk that they are passengers on the York Shuttle Van and request appointment(s) between 8:00 A.M. and 11:00 A.M. to accommodate the vans normal operation schedule. Once the appointment in Lebanon is scheduled the veteran needs to call 771-9218 five (5) working days prior to the appointment to make arrangements to get onto the van. We take the first 8 Veterans and can take stand by names but cannot guarantee a ride. The van driver will get the list of veteran’s names 2-3 days prior to the date and will call the veterans with a departure time. The veterans are responsible for providing their own transportation to York Clinic for departure to Lebanon.')

    #Trip purpose requirements
    ServiceTripPurposeMap.create(service: service, trip_purpose: lebanon)

    #Add geographic restrictions
    ['York', 'Adams'].each do |z|
      c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
      ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
    end

    #Traveler Accommodations Requirements
    folding_wheelchair_accessible = Accommodation.find_by_code('folding_wheelchair_accessible')
    [folding_wheelchair_accessible].each do |n|
      ServiceAccommodation.create(service: service, accommodation: n)
    end

  else
    puts 'Already added Disabled American Vets van'
  end

end


def add_rabbit_general
  provider = Provider.find_by_external_id('1')

  #Create service Disabled American Vets van
  paratransit = ServiceType.find_by_code('paratransit')
  s = Service.find_by_name('General Public Shared Ride')
  unless s.nil?
    return
  end
  service = Service.create(name: 'General Public Shared Ride', provider: provider, service_type: paratransit, advanced_notice_minutes: 24*60)

  #Add Schedules
  (1..5).each do |n|
    Schedule.create(service: service, start_seconds:5.75*3600, end_seconds: 23.5*3600, day_of_week: n)
  end
  Schedule.create(service: service, start_seconds:7.25*3600, end_seconds: 21.75*3600, day_of_week: 6)
  Schedule.create(service: service, start_seconds:9.25*3600, end_seconds: 18*3600, day_of_week: 0)

  #Add geographic restrictions
  ['York', 'Adams'].each do |z|
    c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
    ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
  end
  ['York', 'Adams'].each do |z|
    c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
    ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
  end

  medical = TripPurpose.find_by_code('medical')
  cancer = TripPurpose.find_by_code('cancer_treatment')
  #Trip purpose requirements
  [medical, cancer].each do |n|
    ServiceTripPurposeMap.create(service: service, trip_purpose: n)
  end
  FareStructure.create(service: service, fare_type: 2, desc:  "Zone 1: $15.65, Zone 2: $22.00, Zone 3: $30.50, Zone 4: $44.25")

  #Traveler Accommodations Requirements
  folding_wheelchair_accessible = Accommodation.find_by_code('folding_wheelchair_accessible')
  motorized_wheelchair_accessible = Accommodation.find_by_code('motorized_wheelchair_accessible')
  curb_to_curb = Accommodation.find_by_code('curb_to_curb')
  [motorized_wheelchair_accessible, folding_wheelchair_accessible, curb_to_curb].each do |n|
    ServiceAccommodation.create(service: service, accommodation: n)
  end

end

def add_urls_to_pa

  service = Service.find_by_name('Senior Shared Ride')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end

  service = Service.find_by_name('Shared Ride for Ages 60-64')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end

  service = Service.find_by_name('Medical Assistance Transportation Program')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end

  service = Service.find_by_name('ADA Complementary Service')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end

  service = Service.find_by_name('Service for Persons with Disabilities')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end

  service = Service.find_by_name('Staying Connected')
  unless service.nil?
    service.url = "http://www.stayingconnectedyork.org/"
    service.save
  end

  service = Service.find_by_name('Road to Recovery Program')
  unless service.nil?
    service.url = "http://www.cancer.org/treatment/supportprogramsservices/road-to-recovery"
    service.save
  end

  service = Service.find_by_name('Touch a Life')
  unless service.nil?
    service.url = "http://www.lutheranscp.org/cos/touch-a-life"
    service.save
  end

  service = Service.find_by_name('Area Agency on Aging')
  unless service.nil?
    service.url = "http://yorkcountypa.gov/health-human-services/agency-on-aging.html"
    service.save
  end

  service = Service.find_by_name('General Public Shared Ride')
  unless service.nil?
    service.url = "http://www.rabbittransit.org/"
    service.save
  end
end

def setup_cms
    %w{en es}.each do |locale|
      Translation.where(key: 'splash', locale: locale).first_or_create(value: File.open(File.join('db', 'pa', 'splash.html')).read)
    end
end

def add_booking_service_codes
  services = Service.all
  services.each do |service|
    if service.provider.external_id == '1'
      service.booking_service_code = 'ecolane'
      service.save
    end
  end
end

def create_ecolane_user
  e_user = User.find_by_email('ecolane@camsys.com')
  services = Provider.find_by_external_id('1').services
  services.each do |service|
    mapping = UserService.where(user_profile_id: e_user.user_profile.id, service_id: service.id, external_user_id: '76331').first_or_create
  end

end

def collapse_rabbit_services

  provider = Provider.find_by_external_id('1')

  provider.services.each do |service|
    unless service.external_id == 'shared_ride' || service.external_id == "general_shared_ride"
      service.active = false
      service.save
    end
  end

  medical = TripPurpose.find_by_code('medical')
  cancer = TripPurpose.find_by_code('cancer_treatment')
  general = TripPurpose.find_by_code('general_purpose')
  grocery = TripPurpose.find_by_code('grocery')
  paratransit = ServiceType.find_by_code('paratransit')

  disabled = Characteristic.find_by_code('disabled')
  matp = Characteristic.find_by_code('matp')
  ada_eligible = Characteristic.find_by_code('ada_eligible')
  age = Characteristic.find_by_code('age')

  #Traveler accommodations
  folding_wheelchair_accessible = Accommodation.find_by_code('folding_wheelchair_accessible')
  motorized_wheelchair_accessible = Accommodation.find_by_code('motorized_wheelchair_accessible')
  curb_to_curb = Accommodation.find_by_code('curb_to_curb')

  #Special Services Shared Ride
  s = Service.find_by_external_id('shared_ride')

  if s.nil?

    #Create service Senior Shared Ride
    service = Service.create(name: 'Rabbit Shared Ride', provider: provider, service_type: paratransit, advanced_notice_minutes: 24*60)
    service.external_id = "shared_ride"
    service.booking_service_code = 'ecolane'
    service.save

    FareStructure.create(service: service, fare_type: 0, base: 3.3, desc:  "Zone 1: $2.35, Zone 2: $3.30, Zone 3: $4.60, Zone 4: $6.65")

    #Add Schedules
    (1..5).each do |n|
      Schedule.create(service: service, start_seconds:5.75*3600, end_seconds: 23.5*3600, day_of_week: n)
    end
    Schedule.create(service: service, start_seconds:7.25*3600, end_seconds: 21.75*3600, day_of_week: 6)
    Schedule.create(service: service, start_seconds:9.25*3600, end_seconds: 18*3600, day_of_week: 0)

    # was:
    # [medical, cancer, general, grocery].each do |n|
    #   ServiceTripPurposeMap.create(service: service, trip_purpose: n)
    # end

    #Add geographic restrictions
    ['York', 'Adams'].each do |z|
      c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
      ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
    end
    ['York', 'Adams'].each do |z|
      c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
      ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
    end

    #Traveler Characteristics Requirements
    ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4, group: 1)

    #Traveler Characteristics Requirements
    ServiceCharacteristic.create(service: service, characteristic: matp, value: 'true', group: 2)

    #Traveler Characteristics Requirements
    ServiceCharacteristic.create(service: service, characteristic: ada_eligible, value: 'true', group: 3)

    #Traveler Characteristics Requirements
    ServiceCharacteristic.create(service: service, characteristic: disabled, value: 'true', group: 4)

    #Traveler Accommodations Requirements
    [motorized_wheelchair_accessible, folding_wheelchair_accessible, curb_to_curb].each do |n|
      ServiceAccommodation.create(service: service, accommodation: n)
    end

  end


  ###General Purpose Shared Ride
  s = Service.find_by_external_id('general_shared_ride')

  if s.nil?
    paratransit = ServiceType.find_by_code('paratransit')
    #Create service Senior Shared Ride
    service = Service.create(name: 'Rabbit General Public Shared Ride', provider: provider, service_type: paratransit, advanced_notice_minutes: 24*60)
    service.external_id = "general_shared_ride"
    service.booking_service_code = 'ecolane'
    service.save

    FareStructure.create(service: service, fare_type: 0, base: 22, desc:  "Zone 1: $15.65, Zone 2: $22.00, Zone 3: $30.50, Zone 4: $44.25")

    #Add Schedules
    (1..5).each do |n|
      Schedule.create(service: service, start_seconds:5.75*3600, end_seconds: 23.5*3600, day_of_week: n)
    end
    Schedule.create(service: service, start_seconds:7.25*3600, end_seconds: 21.75*3600, day_of_week: 6)
    Schedule.create(service: service, start_seconds:9.25*3600, end_seconds: 18*3600, day_of_week: 0)
    #Trip purpose requirements

    # [medical, cancer, general, grocery].each do |n|
    #   ServiceTripPurposeMap.create(service: service, trip_purpose: n)
    # end

    #Add geographic restrictions
    ['York', 'Adams'].each do |z|
      c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
      ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
    end
    ['York', 'Adams'].each do |z|
      c = GeoCoverage.find_or_create_by(value: z, coverage_type: 'county_name')
      ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
    end

    #Traveler Accommodations Requirements
    [motorized_wheelchair_accessible, folding_wheelchair_accessible, curb_to_curb].each do |n|
    ServiceAccommodation.create(service: service, accommodation: n)
    end
  end

end


def add_ancillary_services

  #Transit Service
  #Rabbit
  p = Provider.find_by_external_id('1')
  s = ServiceType.where(code: 'transit').first
  service = Service.where(provider: p, service_type: s, external_id: '210').first_or_create
  service.name = "Rabbit Transit"
  service.active = false
  service.save

  #Lebanon
  p = Provider.where(external_id: 'lebanon_transit').first_or_create
  p.name = 'Lebanon Transit'
  p.url ='http://www.lebanontransit.org/'
  p.save
  service = Service.where(provider: p, service_type: s, external_id: '209').first_or_create
  service.name = "Lebanon Transit"
  service.active = false
  service.save

  #Taxi Service
  provider = Provider.create!({name: 'Taxi services'})
  provider.services.create!({name: 'Taxi services', active: false,
     service_type: ServiceType.where(code: 'taxi').first})
end

def create_agencies_and_agency_users
  ['PA 2-1-1'].each do |a|
    agency = Agency.find_by_name(a)
    unless agency.nil?
      puts "#{a} already exists"
      next
    end
    puts "Creating #{a.ai}"
    agency = Agency.create! name: a

    # agency admin
    u = User.create! first_name: a + ' Agency Admin', last_name: 'Agency Admin',
        email: a.downcase.gsub(/ /, '_') + '_admin@camsys.com', password: 'welcome1'
    up = UserProfile.create! user: u
    agency.users << u
    u.add_role :agency_administrator, agency
    u.add_role :internal_contact, agency

    # agency agent
    u = User.create! first_name: a + ' Agent', last_name: 'Agent',
        email: a.downcase.gsub(/ /, '_') + '_agent@camsys.com', password: 'welcome1'
    up = UserProfile.create! user: u
    agency.users << u
    u.add_role :agent, agency
  end

end

### MAIN ###
puts 'Adding PA Sample Data'
add_users_and_places
add_providers_and_services
add_fares
add_dav
#add_rabbit_general
add_urls_to_pa
setup_cms
add_booking_service_codes
collapse_rabbit_services
create_ecolane_user
add_ancillary_services
create_agencies_and_agency_users
puts 'Done Adding PA Sample Data'
