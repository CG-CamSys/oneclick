module ServiceAdapters
  class IandrAdapter

    attr_accessor :providers

    def initialize(providers)
      @providers = providers
    end

    def to_xml(options = {})
      # options[:skip_types] = true
      # options[:dasherize] = false
      builder = options.delete(:builder) || Builder::XmlMarkup.new(options)
      builder.instruct!
      builder.interchange({version: "1.0"}) do |b|
        b.updated_at Time.now
        new_options = {
          builder: b, skip_instruct: true, skip_types: true,
          include: {
            services: {
              include: {
                schedules: {},
                traveler_characteristics: {
                  include: {
                    service_traveler_characteristics_maps: {}
                  }
                  },
                  traveler_accommodations: {
                    include: {
                      service_traveler_accommodations_maps: {}
                    }
                  }
                }
              }
            }
            }.merge(options)
            @providers.to_xml(new_options)
          end
        end

      end
    end
