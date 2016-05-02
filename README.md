## What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. He may one day be a sentient being that interacts with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

### Setup

Whedon uses [`dotenv`](https://github.com/bkeepers/dotenv) to manage local configuration. Take a look at `.env-example` (which needs renaming to `.env` to be picked up).

### Usage

#### Implemented functionality

List all open reviews in the GitHub review repository

```
$ whedon reviews

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.list
```

Open the browser at the review issue page

```
$ whedon open {id}
```

Verify the review issue body has key fields present

```
$ whedon verify {id}

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.new(issue_id).audit
```

Download locally the repository linked to in the review issue

```
$ whedon download {id}

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.new(issue_id).download
```

Compile the paper.md and generate XML metadata. This does the following:
  1. Looks for the paper.md
  1a. If more than one paper.md is found, asks the user to pick
  2. Compiles the markdown to a custom XML: `pandoc -s -f markdown paper.md -o paper.xml --template xml.template`
  3. Compiles the markdown to a custom PDF: `pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md -o paper.xml --template latex.template`
  4. Opens both files locally for inspection

```
$ whedon compile {id}
```

#### (Soon to be) Implemented functionality

Prepare to accept paper into JOSS. This does the following:
  1. Compiles the PDF with: pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template
  2. Uploads the compiled PDF somewhere and update the review issue with a link to the PDF
```
whedon prepare {id}
```

Generate Crossref metadata. This does the following:
  1. Uses the compiled XML document to generate crossref.xml
  2. Uses https://github.com/inukshuk/bibtex-ruby to try and parse citations (see lib/bibtex.rb)
  3. Generates the full XML (see lib/crossref.rb)
  4. Saves the...

```
whedon generate_crossref {id}
```

Accept a paper into JOSS

```
whedon accept {id}
```
