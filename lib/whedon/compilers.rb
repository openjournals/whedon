# This module has methods to compile PDFs and Crossref XML depending upon
# the content type of the paper (Markdown or LaTeX)
module Compilers
  require 'date'
  require 'yaml'

  # Generate the paper PDF
  # Optionally pass in a custom branch name as first param
  def generate_pdf(custom_branch=nil, draft=true, paper_issue=nil, paper_volume=nil, paper_year=nil)
    if paper.latex_source?
      pdf_from_latex(custom_branch, draft, paper_issue, paper_volume, paper_year)
    elsif paper.markdown_source?
      pdf_from_markdown(custom_branch, draft, paper_issue, paper_volume, paper_year)
    end
  end

  def generate_crossref(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    if paper.latex_source?
      crossref_from_latex(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    elsif paper.markdown_source?
      crossref_from_markdown(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    end
  end

  def generate_jats(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    if paper.latex_source?
      jats_from_latex(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    elsif paper.markdown_source?
      jats_from_markdown(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    end
  end

  def pdf_from_latex(custom_branch=nil, draft=true, paper_issue=nil, paper_volume=nil, paper_year=nil)
    # Optionally pass a custom branch name
    `cd #{paper.directory} && git checkout #{custom_branch} --quiet` if custom_branch

    metadata = YAML.load_file("#{paper.directory}/paper.yml")

    for k in ["title", "authors", "affiliations", "keywords"]
      raise "Key #{k} not present in metadata" unless metadata.keys().include?(k)
    end

    # Remove everything that shouldn't be there before processing

    `cd #{paper.directory} && rm *.aux \
    && rm *.blg && rm *.fls && rm *.log\
    && rm *.fdb_latexmk`

    open("#{paper.directory}/header.tex", 'w') do |f|
      f << "% **************GENERATED FILE, DO NOT EDIT**************\n\n"
      f << "\\title{#{metadata["title"]}}\n\n"
      for auth in metadata["authors"]
        f << "\\author[#{auth["affiliation"]}]{#{auth["name"]}}\n"
      end
      for aff in metadata["affiliations"]
        f << "\\affil[#{aff["index"]}]{#{aff["name"]}}\n"
      end
      f << "\n\\keywords{"
      for i in 0...metadata["keywords"].length-1
        f << "#{metadata["keywords"][i]}, "
      end
      f << metadata["keywords"].last
      f << "}\n"
      
      # draft mode by default.
      if draft
        f << "\\usepackage{draftwatermark}\n\n"
      end
    end

    `cd #{paper.directory} && latexmk -f -bibtex -pdf paper.tex`

    if File.exists?("#{paper.directory}/paper.pdf")
      `mv #{paper.directory}/paper.pdf #{paper.directory}/#{paper.filename_doi}.pdf`
      puts "#{paper.directory}/#{paper.filename_doi}.pdf"
    else
      abort("Looks like we failed to compile the PDF")
    end
  end

  def generate_issue(date)
    parsed = Date.parse(date)
    return 1 + ((parsed.year * 12 + parsed.month) - (Time.parse(ENV['JOURNAL_LAUNCH_DATE']).year * 12 + Time.parse(ENV['JOURNAL_LAUNCH_DATE']).month))
  end

  def generate_volume(date)
    parsed = Date.parse(date)
    return parsed.year - (Date.parse(ENV['JOURNAL_LAUNCH_DATE']).year - 1)
  end

  def generate_year(date)
    parsed = Date.parse(date)
    return parsed.year
  end

  def generate_month(date)
    parsed = Date.parse(date)
    return parsed.month
  end

  def generate_day(date)
    parsed = Date.parse(date)
    return parsed.day
  end

  def pdf_from_markdown(custom_branch=nil, draft=true, paper_issue=nil, paper_volume=nil, paper_year=nil)
    latex_template_path = "#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}/latex.template"
    csl_file = "#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}/apa.csl"

    url = "#{ENV['JOURNAL_URL']}/papers/lookup/#{@review_issue_id}"
    response = RestClient.get(url)
    parsed = JSON.parse(response)
    submitted = parsed['submitted']
    published = parsed['accepted']

    # TODO - remove this once JOSE has their editors hooked up in the system
    if ENV['JOURNAL_ALIAS'] == "joss" && !paper.editor.nil?
      editor_lookup_url = "#{ENV['JOURNAL_URL']}/editors/lookup/#{paper.editor}"
      response = RestClient.get(editor_lookup_url)
      parsed = JSON.parse(response)
      editor_name = parsed['name']
      editor_url = parsed['url']
    else
      editor_name = "Pending Editor"
      editor_url = "http://example.com"
    end

    # If we have already published the paper then overwrite the year, volume, issue
    if published
      paper_year = generate_year(published)
      paper_issue = generate_issue(published)
      paper_volume = generate_volume(published)
    else
      published = Time.now.strftime('%d %B %Y')
      paper_year ||= @current_year
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume
    end

    # Optionally pass a custom branch name
    `cd #{paper.directory} && git checkout #{custom_branch} --quiet` if custom_branch

    metadata = {
      "repository" => repository_address,
      "archive_doi" => archive_doi,
      "paper_url" => paper.pdf_url,
      "journal_name" => ENV['JOURNAL_NAME'],
      "review_issue_url" => paper.review_issue_url,
      "issue" => paper_issue,
      "volume" => paper_volume,
      "page" => paper.review_issue_id,
      "logo_path" => "#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}/logo.png",
      "aas_logo_path" => "#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}/aas-logo.png",
      "year" => paper_year,
      "submitted" => submitted,
      "published" => published,
      "formatted_doi" => paper.formatted_doi,
      "citation_author" => paper.citation_author,
      "editor_name" => editor_name,
      "reviewers" => paper.reviewers_without_handles,
      "link-citations" => true
    }

    metadata.merge!({"draft" => true}) if draft

    File.open("#{paper.directory}/markdown-metadata.yaml", 'w') { |file| file.write(metadata.to_yaml) }

    `cd #{paper.directory} && pandoc \
    -V repository="#{repository_address}" \
    -V archive_doi="#{archive_doi}" \
    -V review_issue_url="#{paper.review_issue_url}" \
    -V editor_url="#{editor_url}" \
    -V graphics="true" \
    -o #{paper.filename_doi}.pdf -V geometry:margin=1in \
    --pdf-engine=xelatex \
    --citeproc #{File.basename(paper.paper_path)} \
    --from markdown+autolink_bare_uris \
    --csl=#{csl_file} \
    --template #{latex_template_path} \
    --metadata-file=markdown-metadata.yaml`

    if File.exists?("#{paper.directory}/#{paper.filename_doi}.pdf")
      puts "#{paper.directory}/#{paper.filename_doi}.pdf"
    else
      abort("Looks like we failed to compile the PDF")
    end
  end

  def crossref_from_latex(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    cross_ref_template_path = "#{Whedon.resources}/crossref.template"
    bibtex = Whedon::BibtexParser.new(paper.bibtex_path)

    # Pass the citations that are actually in the paper to the CrossRef
    # citations generator.

    citations_in_paper = File.read(paper.paper_path).scan(/(?<=\\cite\{)\w+/)
    # FIXME
    # Because of the way citations are handled in Pandoc, we need to prepend and @
    # to the front of each of the citation strings.
    citations_in_paper = citations_in_paper.map {|c| c.prepend("@")}

    citations = bibtex.generate_citations(citations_in_paper)
    authors = paper.crossref_authors
    # TODO fix this when we update the DOI URLs
    # crossref_doi = archive_doi.gsub("http://dx.doi.org/", '')

    paper_day ||= Time.now.strftime('%d')
    paper_month ||= Time.now.strftime('%m')
    paper_year ||= @current_year
    paper_issue ||= @current_issue
    paper_volume ||= @current_volume

    `cd #{paper.directory} && pandoc \
    -V timestamp=#{Time.now.strftime('%Y%m%d%H%M%S')} \
    -V doi_batch_id=#{generate_doi_batch_id} \
    -V formatted_doi=#{paper.formatted_doi} \
    -V archive_doi=#{archive_doi} \
    -V review_issue_url=#{paper.review_issue_url} \
    -V paper_url=#{paper.pdf_url} \
    -V joss_resource_url=#{paper.joss_resource_url} \
    -V journal_alias=#{ENV['JOURNAL_ALIAS']} \
    -V journal_abbrev_title=#{ENV['JOURNAL_ALIAS'].upcase} \
    -V journal_url=#{ENV['JOURNAL_URL']} \
    -V journal_name='#{ENV['JOURNAL_NAME']}' \
    -V journal_issn=#{ENV['JOURNAL_ISSN']} \
    -V citations='#{citations}' \
    -V authors='#{authors}' \
    -V month=#{paper_month} \
    -V day=#{paper_day} \
    -V year=#{paper_year} \
    -V issue=#{paper_issue} \
    -V volume=#{paper_volume} \
    -V page=#{paper.review_issue_id} \
    -V title='#{paper.plain_title}' \
    -f markdown #{File.basename(paper.paper_path)} -o #{paper.filename_doi}.crossref.xml \
    --template #{cross_ref_template_path}`

    if File.exists?("#{paper.directory}/#{paper.filename_doi}.crossref.xml")
      "#{paper.directory}/#{paper.filename_doi}.crossref.xml"
    else
      abort("Looks like we failed to compile the Crossref XML")
    end
  end

  def crossref_from_markdown(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    cross_ref_template_path = "#{Whedon.resources}/crossref.template"
    bibtex = Whedon::BibtexParser.new(paper.bibtex_path)

    # Pass the citations that are actually in the paper to the CrossRef
    # citations generator.

    citations_in_paper = File.read(paper.paper_path).scan(/@[\w|\-|:|_|\/|\+]+/)
    citations = bibtex.generate_citations(citations_in_paper)
    authors = paper.crossref_authors
    # TODO fix this when we update the DOI URLs
    # crossref_doi = archive_doi.gsub("http://dx.doi.org/", '')

    url = "#{ENV['JOURNAL_URL']}/papers/lookup/#{@review_issue_id}"
    response = RestClient.get(url)
    parsed = JSON.parse(response)
    submitted = parsed['submitted']
    published = parsed['accepted']

    # If we have already published the paper then overwrite the year, volume, issue
    if published
      paper_day = generate_day(published)
      paper_month = generate_month(published)
      paper_year = generate_year(published)
      paper_issue = generate_issue(published)
      paper_volume = generate_volume(published)
    else
      paper_issue ||= @current_issue
      paper_volume ||= @current_volume
      paper_day ||= Time.now.strftime('%d')
      paper_month ||= Time.now.strftime('%m')
      paper_year ||= Time.now.strftime('%Y')
    end

    metadata = {
      "timestamp" => Time.now.strftime('%Y%m%d%H%M%S'),
      "doi_batch_id" => generate_doi_batch_id,
      "formatted_doi" => paper.formatted_doi,
      "archive_doi" => archive_doi,
      "review_issue_url" => paper.review_issue_url,
      "paper_url" => paper.pdf_url,
      "joss_resource_url" => paper.joss_resource_url,
      "journal_alias" => ENV['JOURNAL_ALIAS'],
      "journal_abbrev_title" => ENV['JOURNAL_ALIAS'].upcase,
      "journal_url" => ENV['JOURNAL_URL'],
      "journal_name" => ENV['JOURNAL_NAME'],
      "journal_issn"=> ENV['JOURNAL_ISSN'],
      "month" => paper_month,
      "day" => paper_day,
      "year" => paper_year,
      "issue" => paper_issue,
      "volume" => paper_volume,
      "page" => paper.review_issue_id,
      "title" => paper.plain_title,
      "crossref_authors" => authors,
      "citations" => citations
    }

    File.open("#{paper.directory}/crossref-metadata.yaml", 'w') { |file| file.write(metadata.to_yaml) }

    `cd #{paper.directory} && pandoc \
    -V title="#{paper.plain_title}" \
    -f markdown #{File.basename(paper.paper_path)} -o #{paper.filename_doi}.crossref.xml \
    --template #{cross_ref_template_path} \
    --metadata-file=crossref-metadata.yaml`

    if File.exists?("#{paper.directory}/#{paper.filename_doi}.crossref.xml")
      doc = Nokogiri::XML(File.open("#{paper.directory}/#{paper.filename_doi}.crossref.xml", "r"), &:noblanks)
      File.open("#{paper.directory}/#{paper.filename_doi}.crossref.xml", 'w') {|f| f.write(doc.to_xml(:indent => 2))}
      "#{paper.directory}/#{paper.filename_doi}.crossref.xml"
    else
      abort("Looks like we failed to compile the Crossref XML")
    end
  end

  def jats_from_latex(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    "JATS from LaTeX"
  end

  def jats_from_markdown(paper_issue=nil, paper_volume=nil, paper_year=nil, paper_month=nil, paper_day=nil)
    latex_template_path = "#{Whedon.resources}/latex.template"
    jats_template_path = "#{Whedon.resources}/jats.template"
    csl_file = "#{Whedon.resources}/jats.csl"


    url = "#{ENV['JOURNAL_URL']}/papers/lookup/#{@review_issue_id}"
    response = RestClient.get(url)
    parsed = JSON.parse(response)
    submitted = parsed['submitted']
    published = parsed['accepted']

    # If we have already published the paper then overwrite the year, volume, issue
    if published
      paper_day = Date.parse(published).strftime('%d')
      paper_year = generate_year(published)
      paper_issue = generate_issue(published)
      paper_volume = generate_volume(published)
    else
      paper_day ||= Time.now.strftime('%d')
      paper_month ||= Time.now.strftime('%m')
      paper_year ||= Time.now.strftime('%Y')
    end

    # TODO: may eventually want to swap out the latex template
    `cd #{paper.directory} && pandoc \
    -V repository="#{repository_address}" \
    -V archive_doi="#{archive_doi}" \
    -V paper_url="#{paper.pdf_url}" \
    -V journal_name='#{ENV['JOURNAL_NAME']}' \
    -V journal_issn=#{ENV['JOURNAL_ISSN']} \
    -V journal_abbrev_title=#{ENV['JOURNAL_ALIAS']} \
    -V graphics="true" \
    -V issue="#{paper_issue}" \
    -V volume="#{paper_volume}" \
    -V page="#{paper.review_issue_id}" \
    -V logo_path="#{Whedon.resources}/#{ENV['JOURNAL_ALIAS']}-logo.png" \
    -V month=#{paper_month} \
    -V day=#{paper_day} \
    -V year="#{paper_year}" \
    -V jats_authors='#{paper.jats_authors}' \
    -V jats_affiliations='#{paper.jats_affiliations}' \
    -t jats \
    -s \
    --citeproc \
    -o #{paper.filename_doi}.jats.xml  \
    #{File.basename(paper.paper_path)} \
    --template #{jats_template_path}`

    if File.exists?("#{paper.directory}/#{paper.filename_doi}.jats.xml")
      "#{paper.directory}/#{paper.filename_doi}.jats.xml"
    else
      abort("Looks like we failed to compile the JATS XML")
    end
  end
end
