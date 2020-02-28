require_relative 'spec_helper'

describe Whedon::Author do

  context "#initials" do
    it "should return first name and middle name initials" do
      subject = Whedon::Author.new("Sarah Michelle Gellar", "", nil, nil)
      expect(subject.initials).to eq("S. M.")
    end

    it "should return first name initial if no middle name present" do
      subject = Whedon::Author.new("Buffy Summers", "", nil, nil)
      expect(subject.initials).to eq("B.")
    end
  end

end
