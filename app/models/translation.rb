class Translation < ActiveRecord::Base

    validates_uniqueness_of :key, scope: :locale, message: "Keys should occur once per language"
    
    validates :key, presence: true

    validates :locale, :value, presence: true

    def self.available_locales
       Translation.uniq.pluck(:locale)
     end
end
