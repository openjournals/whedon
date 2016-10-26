#!\bin\bash
paper_directory=$1
repository_address=$2
archive_doi=$3
paper_url=$4
formatted_doi=$5
review_issue_url=$6
bibfile=$7
filename_doi="output.pdf" #use static name for sake of testing
latex_template_path="../resources/joss.template"
#mytext_citation="Attali, D. (2016, September 20). ezknitr: Avoid the Typical Working Directory Pain When Using knitr The Journal of Open Source Software. The Open Journal. https://doi.org/10.21105/joss.00075"
mytext_citation=$(curl "http://citation.crosscite.org/format?doi=10.21105/joss.00075&style=apa&lang=en-US")

      # TODO: may eventually want to swap out the latex template
      cd $paper_directory && pandoc \
      -V repository=$repository_address \
      -V archive_doi=$archive_doi \
      -V paper_url=$paper_url \
      -V formatted_doi=$formatted_doi \
      -V text_citation="$mytext_citation" \
      -V graphics="true" \
      -V review_issue_url=$review_issue_url \
      -S -o $filename_doi -V geometry:margin=1in \
      --filter pandoc-citeproc $bibfile \
      --template $latex_template_path

