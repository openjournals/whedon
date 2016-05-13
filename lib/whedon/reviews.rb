require_relative 'github'

module Whedon
  class Reviews
    include GitHub

    attr_accessor :review_repository_url

    def initialize(review_repository_url)
      @review_repository_url = review_repository_url
    end

    def list_current
      reviews = Hash.new()

      current_reviews = client.list_issues(@review_repository_url)
      return nil if current_reviews.empty?

      current_reviews.each do |issue|
        reviews[issue.number] = {
                              :opened_at => issue.created_at,
                              :url => issue.html_url
                            }
      end

      return reviews
    end
  end
end
