require_relative 'spec_helper'

describe Whedon::Reviews do

  subject { Whedon::Reviews.new(ENV['JOSS_REVIEW_REPO']) }

  it "can return #review issues" do
    VCR.use_cassette('reviews') do
      expect(subject.list_current.first[1]).to have_key(:opened_at)
    end
  end

  it "can should return the correct number of review issues" do
    VCR.use_cassette('reviews') do
      expect(subject.list_current.size).to eql(5)
    end
  end
end
