# How we connect to GitHub.

module GitHub
  # Authenticated Octokit
  # TODO remove license preview media type when this ships
  MEDIA_TYPE = "application/vnd.github.drax-preview+json"

  def client
    @client ||= Octokit::Client.new(:access_token => ENV['GH_TOKEN'],
                                    :default_media_type => MEDIA_TYPE)
  end
end
