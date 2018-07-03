require_relative 'spec_helper'

describe Whedon::OrcidValidator do

  context "checksum validations" do
    it "should return true for a valid ORCID" do
      subject = Whedon::OrcidValidator.new("0000-0002-3957-2474")
      expect(subject.validate).to be_truthy
    end

    it "should return false for an invalid ORCID" do
      subject = Whedon::OrcidValidator.new("0000-0002-3957-247X")
      expect(subject.validate).to be_falsey
    end
  end

  context "structure validations" do
    it "should fail for a valid ORCID that's badly structured" do
      subject = Whedon::OrcidValidator.new("0000000239572474")
      expect(subject.validate).to be_falsey
    end

    it "should fail for an ORCID with the wrong length" do
      subject = Whedon::OrcidValidator.new("0000-0002-3957-247")
      expect(subject.validate).to be_falsey
    end

    it "should fail for an ORCID invalid characters" do
      subject = Whedon::OrcidValidator.new("0000-000X-3957-2474")
      expect(subject.validate).to be_falsey
    end
  end
end
