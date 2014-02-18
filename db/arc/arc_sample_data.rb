#encoding: utf-8



def add_users_and_places

  places = [
      {active: 1, name: 'My house', raw_address: '730 Peachtree St NE, Atlanta, GA 30308'},
      {active: 1, name: 'Atlanta VA Medical Center', raw_address: '1670 Clairmont Rd, Decatur, GA'},
      {active: 1, name: 'Formación Para el Trabajo', raw_address: '239 West Lake Avenue NW, Atlanta, GA 30314'},
      {active: 1, name: 'Atlanta Mission',  raw_address: '239 West Lake Avenue NW, Atlanta, GA 30314'}
  ]
  users = [
      {first_name: 'Denis', last_name: 'Haskin', email: 'dhaskin@camsys.com'},
      {first_name: 'Derek', last_name: 'Edwards', email: 'dedwards@camsys.com'},
      {first_name: 'Eric', last_name: 'Ziering', email: 'eziering@camsys.com'},
      {first_name: 'Galina', last_name: 'Dymkova', email: 'gdymkova@camsys.com'},
      {first_name: 'Aaron', last_name: 'Magil', email: 'amagil@camsys.com'},
      {first_name: 'Julian', last_name: 'Ray', email: 'jray@camsys.com'},
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
  end
end

def add_providers_and_services
  providers = [
      {name: 'LIFESPAN Resources, Inc.', contact: 'Lauri Stokes', external_id: "esp#1"},
      {name: 'Fayette County', contact: '', external_id: "esp#6"},
      {name: 'Fulton County Office of Aging', contact: 'Ken Van Hoose', external_id: "esp#7"},
      {name: 'Jewish Family & Career Services', contact: 'Gary Miller', external_id: "esp#3"},
      {name: 'Cobb Senior Services', contact: 'Pam Breeden', external_id: "esp#20"},
      {name: 'Rockdale County Senior Services', contact: 'Jackie Lunsford', external_id: "esp#8"},
      {name: 'Cobb Community Transit (CCT)', contact: 'Gary Blackledge', external_id: "esp#15"},
      {name: 'Transportation Services', contact: 'Nell Childers', external_id: "esp#22"},
      {name: 'Volunteer Transportation Service', contact: 'T.J. McGiffert', external_id: "esp#34"}

  ]

  disabled = Characteristic.find_by_code('disabled')
  no_trans = Characteristic.find_by_code('no_trans')
  nemt_eligible = Characteristic.find_by_code('nemt_eligible')
  ada_eligible = Characteristic.find_by_code('ada_eligible')
  veteran = Characteristic.find_by_code('veteran')
  low_income = Characteristic.find_by_code('low_income')
  date_of_birth = Characteristic.find_by_code('date_of_birth')
  age = Characteristic.find_by_code('age')
  walk_distance = Characteristic.find_by_code('walk_distance')

  #Traveler accommodations
  folding_wheelchair_accessible = Accommodation.find_by_code('folding_wheelchair_accessible')
  motorized_wheelchair_accessible = Accommodation.find_by_code('motorized_wheelchair_accessible')
  lift_equipped = Accommodation.find_by_code('lift_equipped')
  door_to_door = Accommodation.find_by_code('door_to_door')
  curb_to_curb = Accommodation.find_by_code('curb_to_curb')
  driver_assistance_available = Accommodation.find_by_code('driver_assistance_available')

  #Service types
  paratransit = ServiceType.find_by_code('paratransit')
  volunteer = ServiceType.find_by_code('volunteer')
  nemt = ServiceType.find_by_code('nemt')

  #trip_purposes
  work = TripPurpose.find_by_code('work')
  training = TripPurpose.find_by_code('training')
  medical = TripPurpose.find_by_code('medical')
  dialysis = TripPurpose.find_by_code('dialysis')
  cancer = TripPurpose.find_by_code('cancer')
  personal = TripPurpose.find_by_code('personal')
  general = TripPurpose.find_by_code('general')
  senior = TripPurpose.find_by_code('senior')
  grocery = TripPurpose.find_by_code('grocery')

  #Create providers and services with custom schedules, eligibility, and accommodations
  providers.each do |provider|
    puts "Add/replace provider #{provider[:external_id]}"

    p = Provider.find_by_external_id(provider[:external_id])
    unless p.nil?
      next
    end

    p = Provider.create! provider
    p.save

    case p.external_id

      when "esp#1" #LIFESPAN Resources
                   #Create service
        service = Service.create(name: 'Volunteer Transportation from', provider: p, service_type: volunteer, advanced_notice_minutes: 14*24*60)
        #Add Schedules
        (2..3).each do |n|
          Schedule.create(service: service, start_seconds:9*3600, end_seconds: 16.5*3600, day_of_week: n)
        end
        #Trip purpose requirements
        [medical, dialysis, cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['30327', '30342', '30319', '30326', '30305', '30324', '30309', '30306', '30363'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'zipcode')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end
        ['30327', '30342', '30319', '30326', '30305', '30324', '30309', '30306', '30363'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'zipcode')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end


        #Traveler Accommodations Requirements
        [door_to_door, curb_to_curb, folding_wheelchair_accessible].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end


      when "esp#6" #Fayette Senior Services
                   #Create service #8
        service = Service.create(name: 'Fayette Senior Services', provider: p, service_type: nemt, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 17*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [medical, dialysis, cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Fayette'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [door_to_door, curb_to_curb, driver_assistance_available, motorized_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#7" #Fulton County office of Aging
                   #Create service #12
        service = Service.create(name: 'Medical Transportation by', provider: p, service_type: nemt, advanced_notice_minutes: 28*24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 17*3600, day_of_week: n)
        end
        #Trip Purpose Requirements
        [medical, dialysis, cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Fulton'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4)
        ServiceCharacteristic.create(service: service, characteristic: no_trans, value: 'false')

        #Traveler Accommodations Provided
        [folding_wheelchair_accessible, driver_assistance_available, motorized_wheelchair_accessible, curb_to_curb, door_to_door, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

        #Create service #11 DARTS
        service = Service.create(name: 'Dial-a-Ride for Seniors (DARTS)', provider: p, service_type: paratransit, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 16.5*3600, day_of_week: n)
        end
        #Trip Purpose Requirements
        [work, training, medical, dialysis, cancer, personal, general].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Fulton'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: age, value: '55', value_relationship_id: 4)

        #Traveler Accommodations Provided
        [folding_wheelchair_accessible, driver_assistance_available, door_to_door, curb_to_curb, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#3" #Jewish Family & Career Center
                   #Create service #3
        service = Service.create(name: 'JETS Transportation Program', provider: p, service_type: volunteer, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 15*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [medical, dialysis, cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['30305', '30306', '30308', '30309', '30319', '30324', '30326', '30327', '30328' ,'30329', '30338', '30339', '30340', '30341' ,'30342', '30345', '30063', '30067', '30068', '30084', '30356', '30350', '30060', '30030', '30033', '30084', '30075', '30076', '30022', '30092', '30080'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'zipcode')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        ['30305', '30306', '30308', '30309', '30319', '30324', '30326', '30327', '30328' ,'30329', '30338', '30339', '30340', '30341' ,'30342', '30345', '30063', '30067', '30068', '30084', '30356', '30350', '30060', '30030', '30033', '30084', '30075', '30076', '30022', '30092', '30080'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'zipcode')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Accommodations Requirements
        [door_to_door, curb_to_curb, driver_assistance_available, folding_wheelchair_accessible, motorized_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#20" #Cobb Senior Services
                    #Create service #36
        service = Service.create(name: 'Cobb Senior Services', provider: p, service_type: paratransit, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8*3600, end_seconds: 14*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [work, training, medical, dialysis, cancer, personal, general].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Cobb'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [door_to_door, curb_to_curb, driver_assistance_available, folding_wheelchair_accessible, motorized_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#15" #Cobb Community Transit
                    #Create service #29
        service = Service.create(name: 'CCT Paratransit', provider: p, service_type: paratransit, advanced_notice_minutes: 7*24*60)
        #Add Schedules
        (1..6).each do |n|
          Schedule.create(service: service, start_seconds:9*3600, end_seconds: 17*3600, day_of_week: n)
        end
        Schedule.create(service: service, start_seconds:12*3600, end_seconds: 16*3600, day_of_week: 0)

        #Trip Purpose Requirements
        [work, training, medical, dialysis, cancer, personal, general].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Cobb'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        ['Cobb'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: ada_eligible, value: 'true')

        #Traveler Accommodations Requirements
        [curb_to_curb, folding_wheelchair_accessible, motorized_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#22" #Mountain Area Transportation Services
                    #Create service #41
        service = Service.create(name: 'Cherokee Area', provider: p, service_type: paratransit, advanced_notice_minutes: 24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 17*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [work, training, medical, dialysis, cancer, personal, general].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Cherokee'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: ada_eligible, value: 'true')

        #Traveler Accommodations Requirements
        [curb_to_curb, door_to_door, folding_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#34" #I care transportation service.
                    #Create Service 55
        service = Service.create(name: 'I Care', provider: p, service_type: volunteer, advanced_notice_minutes: 7*24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:8.5*3600, end_seconds: 16.5*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [medical, dialysis, cancer].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['DeKalb'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        ['DeKalb'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: disabled, value: 'true')
        ServiceCharacteristic.create(service: service, characteristic: age, value: '55', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [curb_to_curb].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

      when "esp#8" #Rockdale County Senior Services
                   #Create Service 15
        service = Service.create(name: 'Rockdale County Senior Services', provider: p, service_type: paratransit, advanced_notice_minutes: 7*24*60)
        #Add Schedules
        (1..5).each do |n|
          Schedule.create(service: service, start_seconds:7.5*3600, end_seconds: 11*3600, day_of_week: n)
        end

        #Trip Purpose Requirements
        [work, training, medical, dialysis, cancer, personal, general].each do |n|
          ServiceTripPurposeMap.create(service: service, trip_purpose: n, value: 'true')
        end

        #Add geographic restrictions
        ['Rockdale'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'origin')
        end

        ['Rockdale'].each do |z|
          c = GeoCoverage.new(value: z, coverage_type: 'county_name')
          ServiceCoverageMap.create(service: service, geo_coverage: c, rule: 'destination')
        end

        #Traveler Characteristics Requirements
        ServiceCharacteristic.create(service: service, characteristic: age, value: '60', value_relationship_id: 4)

        #Traveler Accommodations Requirements
        [curb_to_curb, door_to_door, driver_assistance_available, folding_wheelchair_accessible, motorized_wheelchair_accessible, lift_equipped].each do |n|
          ServiceAccommodation.create(service: service, accommodation: n, value: 'true')
        end

    end

  end
end

def add_fares
  puts 'Creating Fares for ARC Services'
  service = Service.find_by_name('JETS Transportation Program')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "Rides are $12 each way inside the perimeter, $13 each way outside the perimeter, and $22 for wheelchair ride each way.  Rides 12 miles or more are charged a mileage surcharge")
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Medical Transportation by')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Volunteer Transportation from')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Fayette Senior Services')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "Sliding scale is used to determine the fee.")
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Dial-a-Ride for Seniors (DARTS)')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Cobb Senior Services')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 1.00)
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('CCT Paratransit')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 4.00)
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('Cherokee Area')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 2, desc: "Call for current rates.  One way $1.50 for up to 5 miles and $0.30 each additional mile.  Wheelchair is $3.85 for up to 10 miles and $0.42 each additional mile.")
  else
    puts "Fare already exists for " + service.name
  end

  service = Service.find_by_name('I Care')
  if service and service.fare_structures.count == 0
    FareStructure.create(service: service, fare_type: 0, base: 0.00)
  else
    puts "Fare already exists for " + service.name
  end
end

def add_esp_ids

  service = Service.find_by_name('JETS Transportation Program')
  if service
    p "updated service: " + service.name
    service.external_id = "89144135357234431111"
    service.save
  end

  service = Service.find_by_name('Medical Transportation by')
  if service
    p "updated service: " + service.name
    service.external_id = "32138199527497131111"
    service.save
  end

  service = Service.find_by_name('Fayette Senior Services')
  if service
    p "updated service: " + service.name
    service.external_id = "86869601213076809999"
    service.save
  end

  service = Service.find_by_name('Dial-a-Ride for Seniors (DARTS)')
  if service
    p "updated service: " + service.name
    service.external_id = "54104859570670229999"
    service.save
  end

  service = Service.find_by_name('CCT Paratransit')
  if service
    p "updated service: " + service.name
    service.external_id = "57874876269921009999"
    service.save
  end

  service = Service.find_by_name('Cherokee Area')
  if service
    p "updated service: " + service.name
    service.external_id = "65980602734372809999"
    service.save
  end

  provider = Provider.find_by_external_id("esp#6")
  if provider
    p "updating provider:  "  + provider.name
    provider.external_id = "17471"
    provider.save
  end

  provider = Provider.find_by_external_id("esp#7")
  if provider
    p "updating provider:  "  + provider.name
    provider.external_id = "17472"
    provider.save
  end

  provider = Provider.find_by_external_id("esp#3")
  if provider
    p "updating provider:  "  + provider.name
    provider.external_id = "17436"
    provider.save
  end

  provider = Provider.find_by_external_id("esp#15")
  if provider
    p "updating provider:  "  + provider.name
    provider.external_id = "17625"
    provider.save
  end

  provider = Provider.find_by_external_id("esp#22")
  if provider
    p "updating provider:  "  + provider.name
    provider.external_id = "18575"
    provider.save
  end
end

def add_companion
  #Add Companion Allowed Accommodation
  companion_allowed = Accommodation.find_or_initialize_by_code('companion_allowed')
  companion_allowed.name = 'Traveler Companion Permitted'
  companion_allowed.note = 'Do you travel with a companion?'
  companion_allowed.datatype = 'bool'
  companion_allowed.save()
end

def setup_cms
  Cms::Site.destroy_all
  site = Cms::Site.where(identifier: 'default').first_or_create(label: 'default', hostname: 'localhost', path: 'content')
  # site.snippets.create! identifier: 'plan-a-trip', label: 'plan a trip', content: '<div class="well">This is the content for Plan A Trip</div>'
  # site.snippets.create! identifier: 'home-top-logged-in', label: 'home-top-logged-in', content: '<div class="well">This is content for home-top-logged-in</div>'
  # site.snippets.create! identifier: 'home-top', label: 'home-top', content: '<div class="well">This is content for home-top</div>'
  # site.snippets.create! identifier: 'home-bottom-left-logged-in', label: 'home-bottom-left-logged-in', content: '<div class="well">This is content for home-bottom-left-logged-in</div>'
  # site.snippets.create! identifier: 'home-bottom-center-logged-in', label: 'home-bottom-center-logged-in', content: '<div class="well">This is content for home-bottom-center-logged-in</div>'
  # site.snippets.create! identifier: 'home-bottom-right-logged-in', label: 'home-bottom-right-logged-in', content: '<div class="well">This is content for home-bottom-right-logged-in</div>'
  # site.snippets.create! identifier: 'home-bottom-left', label: 'home-bottom-left', content: '<div class="well">This is content for home-bottom-left</div>'
  # site.snippets.create! identifier: 'home-bottom-center', label: 'home-bottom-center', content: '<div class="well">This is content for home-bottom-center</div>'
  # site.snippets.create! identifier: 'home-bottom-right', label: 'home-bottom-right', content: '<div class="well">This is content for home-bottom-right</div>'
  brand = Oneclick::Application.config.brand
      text = <<EOT
<h2 style="text-align: justify;">1-Click/ARC helps you find options to get from here to there, using public transit,
 door-to-door services, and specialized transportation.  Give it a try, and
 <a href="mailto://OneClick@camsys.com">tell us</a> what you think.</h2>
EOT
      site.snippets.create! identifier: 'home-top-logged-in', label: 'home-top-logged-in', content: text
      site.snippets.create! identifier: 'home-top', label: 'home-top', content: text
      text = <<EOT
1-Click/ARC was funded by the
 <a href="http://www.fta.dot.gov/grants/13094_13528.html" target=_blank>Veterans Transportation
 Community Living Initiative</a>.
EOT
      site.snippets.create! identifier: 'home-bottom-left-logged-in', label: 'home-bottom-left-logged-in', content: text
      site.snippets.create! identifier: 'home-bottom-left', label: 'home-bottom-left', content: text
      text = <<EOT
<span style="float: right;">1-Click/ARC is sponsored by the
<a href="http://www.atlantaregional.com/" target=_blank>Atlanta Regional Commission</a>.</span>
EOT
      site.snippets.create! identifier: 'home-bottom-right-logged-in', label: 'home-bottom-right-logged-in', content: text
      site.snippets.create! identifier: 'home-bottom-right', label: 'home-bottom-right', content: text
      text = <<EOT
Tell us about your trip.  The more information you give us, the more options we can find!
EOT
      site.snippets.create! identifier: 'plan-a-trip', label: 'plan a trip', content: text

end

def create_agencies
  ['Atlanta Regional Commission',
   'ARC Mobility Management',
   'ARC Agewise',
   'ARC Workforce Development',
   'Veterans Affairs',
   'Disability Link',
   'Cobb County Transit',
   'Goodwill Industries'].each do |a|
    a = Agency.find_by_name(a)
    unless a.nil?
      next
    end
    Agency.create! name: a
  end

end

### MAIN ###
puts 'Adding ARC Sample Data'
add_users_and_places
add_providers_and_services
add_fares
add_esp_ids
add_companion
setup_cms
create_agencies
puts 'Done Adding ARC Sample Data'