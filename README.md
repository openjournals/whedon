## What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. He may one day be a sentient being that interacts with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

### Setup

Whedon uses [`dotenv`](https://github.com/bkeepers/dotenv) to manage local configuration. Take a look at `.env-example` (which needs renaming to `.env` to be picked up).

Whedon requires a local installation of Pandoc 2 and Pandoc-Citeproc as well as
LaTeX. See [Pandoc's install instruction](http://pandoc.org/installing.html) for details.

### Is it green?

Hopefully...

[![Build Status](https://travis-ci.org/openjournals/whedon.svg?branch=master)](https://travis-ci.org/openjournals/whedon)

### Installation

Depending on how Ruby is installed on your system there might slightly different steps be necessary. [Bundler](http://bundler.io/) is used to install dependencies.

On macOS and with a Homebrew installed Ruby Bundler should be installable with

   gem install bundler

On other Linux distros this might be a separate package or already installed.

After cloning the `whedon` repository with

    git clone https://github.com/openjournals/whedon.git

run (in the 'whedon' directory)

    bundle install

or

    bundle install --path vendor/bundle

Next, it's necessary to create a `.env` file based on the example
[`.env.text`](https://github.com/openjournals/whedon/blob/master/.env.test).

The `GH_TOKEN` can be created following the instructions from GitHub's
[help pages](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/).

Once you have edited the `.env` file you can run the commands described below.
It might be necessary to prefix the `whedon` command with `bundle exec` or
give the full path to the executable, e.g. `./bin/whedon`.


### Usage

#### Implemented functionality

List available commands
```
$ whedon
```

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

Compile a downloaded paper locally to a PDF

```
$ whedon prepare {id}
```

Compile the paper.md and generate XML metadata. This does the following:
  1. Looks for the paper.md
  1a. If more than one paper.md is found, asks the user to pick
  2. Compiles the markdown to a custom XML: `pandoc -s -f markdown paper.md -o paper.xml --template xml.template`
  3. Compiles the markdown to a custom PDF: `pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template`
  4. Opens both files locally for inspection

```
$ whedon compile {id}
```

#### (Soon to be) Implemented functionality

Prepare to accept paper into JOSS. This does the following:
  1. Compiles the PDF with: `pandoc -S -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template`
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
