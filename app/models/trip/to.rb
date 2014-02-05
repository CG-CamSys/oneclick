module Trip::To
  extend ActiveSupport::Concern

  included do
    attr_accessor :to_lat, :to_lon, :to_place, :to_is_home, :to_place_selected, :to_place_selected_type, :to_raw_address

    validates :to_place, :presence => true
    validate :validate_to_selection
  end

protected

  # Validation. Check that there has been a selection for the to place
  def validate_to_selection
    if to_place_selected.blank? || to_place_selected_type.blank?
      errors.add(:to_place, I18n.translate(:nothing_found))
      return false
    end
  end
end