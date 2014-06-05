require 'active_support/concern'

module Rateable
  extend ActiveSupport::Concern

  included do
    has_many :ratings, as: :rateable
    accepts_nested_attributes_for :ratings
  end

  def get_avg_rating # if we need to build out a caching column, impose it here.
    calculate_rating
  end

  # Average rating for rateable.  Returns 0 if unrated
  def calculate_rating
    if self.ratings.blank? # Short circuit out if rateable is unrated
      return 0
    end
    total = self.ratings.pluck(:value).inject(:+)
    len = self.ratings.length
    average = total.to_f / len # to_f so we don't get an integer result
  end

  def rate(user, value, comments=nil)
    Rails.logger.info "User: #{user.id}, rateable: #{self.class}-##{self.id}"
    rate = ratings.build.tap do |r|
      r.user = user # user creating the rating.  Can be traveler or agent
      r.value = value
      r.comments = comments
    end
    rate.save
    rate
  end

  # Sue me, I know it's mixing presentation logic and model logic.  
  # Do not confuse with RatingDecorator#rating_in_stars which performs equivalent action for Rating model (which is not a Rateable model)
  def rating_in_stars(size=1)
    rating = get_avg_rating
    html = "<span id='stars'>"
    for i in 1..5
      if i <= rating
        html << "<i class='x fa fa-star fa-#{size}x'> </i>"
      else
        html << "<i class='x fa fa-star-o fa-#{size}x'> </i>"
      end
    end
    html << "</span>"
    return html.html_safe
  end

end