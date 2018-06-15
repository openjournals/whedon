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
    expect(citations_xml.search('citation[key="ref6"]').text).to match(/Integrating%20Abstractions%20to%20Enhance%20the%20Execution%20of%20Distributed%20Applications, Turilli,%20Matteo%20and%20Zhang,%20Zhao%20and%20Merzky,%20Andre%20and%20Wilde,%20Michael%20and%20Weissman,%20Jon%20and%20Katz,%20Daniel%20S%20and%20Jha,%20Shantenu%20and%20others, arXiv%20preprint%20arXiv:1504.04720, 2015/)
  end
end
