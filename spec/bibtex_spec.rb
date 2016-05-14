require_relative 'spec_helper'
require 'nokogiri'

describe Whedon::Bibtex do

  subject { Whedon::Bibtex.new('fixtures/paper/paper.bib') }

  it "should know how to generate DOI citations" do
    citations_xml = Nokogiri::XML(subject.generate_citations)
    expect(citations_xml.search('citation[key="ref1"]').children.first.name).to eql("doi")
    expect(citations_xml.search('citation[key="ref1"]').text).to eql("10.1109/SERVICES.2007.63")
  end

  it "should know how to generate non-DOI citations" do
    citations_xml = Nokogiri::XML(subject.generate_citations)
    expect(citations_xml.search('citation[key="ref6"]').children.first.name).to eql("unstructured_citation")
    expect(citations_xml.search('citation[key="ref6"]').text).to match(/Integrating Abstractions to Enhance the Execution of Distributed Application/)
  end
end
