#encoding: utf-8
namespace :oneclick do
  namespace :arc do

    desc "Add Fare Structures for ARC"
    task :add_fares => :environment do

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

    end # task

    desc "Add ESP Identifiers to Providers and Services"
    task :add_esp_ids => :environment do

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

    end # task

    desc "Add Companion Allowed Accommodation"
    task :add_companion => :environment do
      companion_allowed = Accommodation.find_or_initialize_by_code('companion_allowed')
      companion_allowed.name = 'Traveler Companion Permitted'
      companion_allowed.note = 'Do you travel with a companion?'
      companion_allowed.datatype = 'bool'
      companion_allowed.save()
    end

    desc "Associate Shapefile Boundaries with Services"
    task :add_boundaries => :environment do
      #Delete all polygon-based boundaries
      gcs = GeoCoverage.where(coverage_type: 'polygon')
      gcs.each do |gc|
        gc.service_coverage_maps.destroy_all
        gc.delete
      end

      Boundary.all.each do |b|
        gc = GeoCoverage.new(value: b.agency, coverage_type: 'polygon', boundary: b)
        case b.agency
          when "Cobb Community Transit (CCT)"
            service = Service.find_by_external_id("54104859570670229999")
            ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'origin')
            ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'destination')
          when "Cherokee Area Transportation System (CATS)"
            service = Service.find_by_external_id("32138199527497131111")
            ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'origin')
            ServiceCoverageMap.create(service: service, geo_coverage: gc, rule: 'destination')
          #when "Gwinnett County Transit (GCT)"
          #when "Metropolitan Atlanta Rapid Transit Authority"
        end
      end
    end

    desc "Set up cms entries"
    task cms: :environment do
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
      case brand

      when 'arc'
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

      when 'pa'
        text = <<EOT
<h2 style="text-align: justify;">1-Click/PA helps you find options to get from here to there, using public transit,
 door-to-door services, and specialized transportation.  Give it a try, and
 <a href="mailto://OneClick@camsys.com">tell us</a> what you think.</h2>
EOT
        site.snippets.create! identifier: 'home-top-logged-in', label: 'home-top-logged-in', content: text
        site.snippets.create! identifier: 'home-top', label: 'home-top', content: text
        text = <<EOT
1-Click/PA was funded by the
 <a href="http://www.fta.dot.gov/grants/13094_13528.html" target=_blank>Veterans Transportation 
 Community Living Initiative</a>.
EOT
        site.snippets.create! identifier: 'home-bottom-left-logged-in', label: 'home-bottom-left-logged-in', content: text
        site.snippets.create! identifier: 'home-bottom-left', label: 'home-bottom-left', content: text
        text = <<EOT
<span style="float: right;">1-Click/PA is sponsored by the
<a href="http://www.dot.state.pa.us/" target=_blank>Pennsylvania Department of Transportation</a> and the
<a href="http://www.rabbittransit.org/" target=_blank>York Adams Transportation Authority</a>.</span>
EOT
        site.snippets.create! identifier: 'home-bottom-right-logged-in', label: 'home-bottom-right-logged-in', content: text
        site.snippets.create! identifier: 'home-bottom-right', label: 'home-bottom-right', content: text
        text = <<EOT
Tell us about your trip.  The more information you give us, the more options we can find!
EOT
        site.snippets.create! identifier: 'plan-a-trip', label: 'plan a trip', content: text

      when 'broward'
        text = <<EOT
<h2 style="text-align: justify;">1-Click/Broward helps you find options to get from here to there, using public transit,
 door-to-door services, and specialized transportation.  Give it a try, and
 <a href="mailto://OneClick@camsys.com">tell us</a> what you think.</h2>
EOT
        site.snippets.create! identifier: 'home-top-logged-in', label: 'home-top-logged-in', content: text
        site.snippets.create! identifier: 'home-top', label: 'home-top', content: text
        text = <<EOT
1-Click/Broward was funded by the
 <a href="http://www.fta.dot.gov/grants/13094_13528.html" target=_blank>Veterans Transportation 
 Community Living Initiative</a>.
EOT
        site.snippets.create! identifier: 'home-bottom-left-logged-in', label: 'home-bottom-left-logged-in', content: text
        site.snippets.create! identifier: 'home-bottom-left', label: 'home-bottom-left', content: text
        text = <<EOT
<span style="float: right;">1-Click/Broward is sponsored by 
<a href="http://211-broward.org/" target=_blank>2-1-1 Broward</a>.</span>
EOT
        site.snippets.create! identifier: 'home-bottom-right-logged-in', label: 'home-bottom-right-logged-in', content: text
        site.snippets.create! identifier: 'home-bottom-right', label: 'home-bottom-right', content: text
        text = <<EOT
Tell us about your trip.  The more information you give us, the more options we can find!
EOT
        site.snippets.create! identifier: 'plan-a-trip', label: 'plan a trip', content: text
      else
        raise "Don't know how to handle brand #{brand}"
      end
    end

  end
end
