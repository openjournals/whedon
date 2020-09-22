# What is Whedon?

Whedon is a collection of command-line utilities to manage JOSS submissions. Whedon is used by the [Whedon-API bot](https://github.com/openjournals/whedon-api) to interact with authors and reviewers during the review process on https://github.com/openjournals/joss-reviews

## Setup

Whedon uses [`dotenv`](https://github.com/bkeepers/dotenv) to manage local configuration. Take a look at `.env-example` (which needs renaming to `.env` to be picked up).

Whedon requires a local installation of Pandoc 2 and Pandoc-Citeproc as well as a LaTeX (ideally [TeXLive](https://www.tug.org/texlive/)) installation. See [Pandoc's install instruction](http://pandoc.org/installing.html) for details.

## Is it green?

Hopefully...

[![Build Status](https://travis-ci.org/openjournals/whedon.svg?branch=master)](https://travis-ci.org/openjournals/whedon)

## Installation

Depending on how Ruby is installed on your system there might slightly different steps be necessary. Note that Whedon is only tested for reasonably modern versions of Ruby (i.e. > 2.1) [Bundler](http://bundler.io/) is used to install dependencies.

On macOS and with a Homebrew installed Ruby Bundler should be installable with

```
gem install bundler
```

On other Linux distros this might be a separate package or already installed.

After cloning the `whedon` repository with

```
git clone https://github.com/openjournals/whedon.git
```

from within the `whedon` directory run the following command:

```
bundle install
```

or

```
bundle install --path vendor/bundle
```

Next, it's necessary to create a `.env` file based on the example
[`.env.test`](https://github.com/openjournals/whedon/blob/master/.env.test).

The `GH_TOKEN` can be created following the instructions from GitHub's
[help pages](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/).

Once you have edited the `.env` file you can run the commands described below.
It might be necessary to prefix the `whedon` command with `bundle exec` or
give the full path to the executable, e.g. `./bin/whedon`.

## Usage

There are two main ways to use `Whedon`, 1) via the command-line utility or 2) using the Ruby API. If you want to see how the command line is implemented, take a look at the [executable](https://github.com/openjournals/whedon/blob/master/bin/whedon).

### Currently implemented functionality

List available commands:

```
$ bundle exec whedon # or just 'whedon' depending on whether you have built and installed the RubyGem locally

Commands:
  whedon compile         # Compile the paper and XML metadata
  whedon deposit         # Deposit the metadata with the JOSS application and Crossref
  whedon download        # Download the repo
  whedon help [COMMAND]  # Describe available commands or one specific command
  whedon open            # Open browser for review
  whedon prepare         # Just prepare the PDF
  whedon reviews         # Lists open reviews
  whedon verify          # Check the key values in the review issue
```

**whedon reviews**

List all open reviews in the GitHub review repository:

```ruby
$ whedon reviews

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.list
```

**whedon verify**

Verify the review issue body has key fields present:

```ruby
$ whedon verify {id}

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.new(issue_id).audit
```

**whedon open**

Open the browser at the review issue page

```
$ whedon open {id}
```

**whedon download**

Download locally the repository linked to in the review issue (note this tries to do a simple `git clone` of the repository address which will fail for non-git repositories).

```ruby
$ whedon download {id}

# Ruby API equivalent
>> require 'whedon'
>> Whedon::Paper.new(issue_id).download
```

**whedon prepare**

Compile a downloaded paper locally to a PDF.

This is the command that the `Whedon-API` bot uses to generate a preview of the paper PDF for sharing with reviewers and editors.

```ruby
$ whedon prepare {id}

# Ruby API equivalent
>> require 'whedon'
>> review = Whedon::Review.new(issue_id)
>> processor = Whedon::Processor.new(issue_id, review.issue_body)
>> processor.set_paper(path_to_paper.md_file)
>> processor.generate_pdf
```

Under the hood, the `prepare` method does the following:

- Looks for the paper.md
  - If more than one paper.md is found, asks the user to pick the correct one
- Compiles the markdown to a custom PDF: `pandoc -o paper.pdf -V geometry:margin=1in --filter pandoc-citeproc paper.md --template latex.template`. See the actual [command here](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L101-L122).
- Returns the filesystem location of the compiled PDF for inspection


**whedon compile**

```ruby
$ whedon compile {id}

# Ruby API equivalent
>> require 'whedon'
>> review = Whedon::Review.new(issue_id)
>> processor = Whedon::Processor.new(issue_id, review.issue_body)
>> processor.set_paper(path_to_paper.md_file)
>> processor.compile
```

Under the hood, the `compile` method does the following:

- Looks for the paper.md
  - If more than one paper.md is found, asks the user to pick the correct one
- Compiles the markdown to [four different outputs](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L82-L87):
  - [The JOSS PDF](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L101-L122)
  - A (currently un-used) [custom XML output](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L149-L167)
  - An [HTML representation](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L169-L206) of the paper (deprecated)
  - The [Crossref deposit metadata](https://github.com/openjournals/whedon/blob/25f9a1307a83b6b89080d6d934a3621f6a244035/lib/whedon/processor.rb#L208-L247)
- Returns the filesystem location of the compiled PDF for inspection

### Functionality under development

Accept a paper into JOSS. This method currently returns the necessary metadata for the JOSS application (i.e. fields that need updating in the [JOSS database](https://github.com/openjournals/joss/blob/ce7722c2ec6d1ff306b13f465887e9747c76b3b1/db/schema.rb#L35-L55)) once a paper is accepted.

In the future, this method should:

- Update the database fields automatically on the JOSS application.
- Deposit the Crossref XML to the Crossref API

```ruby
$ whedon deposit {id}

# Ruby API equivalent
>> require 'whedon'
>> review = Whedon::Review.new(issue_id)
>> processor = Whedon::Processor.new(issue_id, review.issue_body)
>> processor.set_paper(path_to_paper.md_file)
>> processor.deposit
```
