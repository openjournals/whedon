require_relative 'github'
require 'pry'
module Whedon
  class Reviews
    include GitHub

    attr_accessor :review_repository_url

    # Initialize the GitHub class
    def initialize(repository_url)
      @review_repository_url = repository_url
    end

    def current
      current_reviews = client.list_issues(@review_repository_url)
      return "No open reviews" if current_reviews.empty?

      current_reviews.each do |issue|
        puts issue.html_url
        puts "Opened: #{issue.created_at}"
        puts ""
      end
      nil
    end
  end
end
