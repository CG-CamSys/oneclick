require 'lorem-ipsum'

#encoding: utf-8
namespace :oneclick do
  task :seed_data => :environment do
    throw Exception.new("*** Deprecated, just use db:seed task ***")
  end

  task version: :environment do
    version = `git describe`.chomp
    File.open('config/initializers/version.rb', 'w') do |f|
      f.puts "Oneclick::Application.config.version = '#{version}'"
    end
  end
   # OBJECTID  LONGITUDE LATITUDE  FACNAME ADDRESS_1 ADDRESS_2 CITY  STATE ZIP AREACODE  PHONE FIPS  COUNTY  TYPE  METHOD
  task convert_shp_to_csv: :environment do
    require 'rgeo/shapefile'
    require 'csv'
    geocoder = OneclickGeocoder.new
    poi_types = Set.new
    c = 0
    CSV.open("output.csv", "wb", {col_sep: "\t"}) do |csv|
      csv << %w{OBJECTID  LONGITUDE LATITUDE  FACNAME ADDRESS_1 ADDRESS_2 CITY  STATE ZIP AREACODE  PHONE FIPS  COUNTY  TYPE  METHOD}
      RGeo::Shapefile::Reader.open(ENV['SHAPEFILE']) do |shapefile|
        input_rows = shapefile.size
        shapefile.each do |shape|
          # puts shape.inspect
          begin
            success, errors, results = geocoder.reverse_geocode(shape.geometry.y, shape.geometry.x)
            unless success
              puts "Geocode failed:"
              puts errors.inspect
              puts shape.inspect
              sleep(10)
              next
            end
            result = results[0]
            csv << [shape['ObjectID'], shape.geometry.x, shape.geometry.y, shape['NAME'], result[:street_address],
            nil,
            result[:city], result[:state], result[:zip], nil, nil, shape['STCTYFIPS'], result[:county],
            shape['FEATTYPE'], 'ArcGIS']
            poi_types << shape['FEATTYPE']
            # break if c >= 2
          rescue Exception => e
            puts "Exception: #{e}"
            puts "Shape: #{shape.inspect}"
          end
          c += 1
          puts "#{c} / #{input_rows}"
          # sleep(rand(5))
        end
      end
    end

    puts poi_types.to_a.join("\n")

  end

  task extract_shp: :environment do
    require 'rgeo/shapefile'
    # require 'csv'
    # geocoder = OneclickGeocoder.new
    poi_types = Set.new
    c = 0
    type_count = Hash.new(0)
    CSV.open("output.csv", "wb", {col_sep: "\t"}) do |csv|
      csv << %w{OBJECTID  LONGITUDE LATITUDE  FACNAME ADDRESS_1 ADDRESS_2 CITY  STATE ZIP AREACODE  PHONE FIPS  COUNTY  TYPE  METHOD}
      Dir.glob('/Users/dedwards/Downloads/ParatransitBuffer_100812/*.shp').each do |shp|
        puts shp
        RGeo::Shapefile::Reader.open(shp) do |shapefile|
          # input_rows = shapefile.size
          shapefile.each do |shape|
            next if shape['NAME'].blank?
            # puts shape.attributes.select{|k, v| !v.blank?}
            shape.attributes.select{|k, v| !v.blank? and !['OSM_ID', 'NAME'].include?(k)}.each do |k, v|
              type_count[[k, v].join('|')] += 1
            end

            # AMENITY, LANDUSE, LEISURE, PLACE, SHOP, TOURISM
            # puts shape.geometry.x/(10**5)
            # puts shape.geometry.y/(10**5)
            # puts
            row = [shape['OSM_ID']]
            row << shape.geometry.x/(10**5)
            row << shape.geometry.y/(10**5)
            row << shape['NAME']
            row << nil # street address
            row << nil
            row << nil # city
            row << nil # state
            row << nil # zip
            row << nil
            row << nil
            row << nil # county FIPS
            row << nil # county
            row << (%w{AMENITY LANDUSE LEISURE PLACE SHOP TOURISM} & shape.attributes.keys).first
            row << 'OSM'
            csv << row
            c += 1
          end
        end
      end
    end

    # puts c
    # type_count.each do |k, v|
    #   puts [k, v].join("\t")
    # end
  end

  task fix_roles: :environment do
    Role.destroy_all
    ROLES.each do |r|
      Role.create! name: r
    end
    # For old times's sake
    Role.create! name: :admin
    u = User.find_by_email('email@camsys.com')
    u.add_role 'System Administrator'
    u.add_role :admin
  end


end
