require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Processor do

  subject { Whedon::Processor.new(17, File.read('fixtures/review_body.txt')) }

end
