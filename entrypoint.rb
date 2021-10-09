#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler"
Bundler.require

require "base64"
require "logger"
require "optparse"

logger = Logger.new($stdout)
logger.level = Logger::INFO

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: entrypoint.rb [options]"

  opts.on("-r ", "--repository REPOSITORY", "The project repository") do |repository|
    options[:repository] = repository
  end

  opts.on("-t", "--tap REPOSITORY", "The Homebrew tap repository") do |tap|
    options[:tap] = tap
  end

  opts.on("-f", "--formula PATH", "The path to the formula in the tap repository") do |path|
    options[:formula] = path
  end

  opts.on("-d", "--download-url DOWNLOAD-URL", "The download release url") do |download_url|
    options[:download_url] = download_url
  end

  opts.on("-s", "--sha256 DOWNLOAD-URL-SHA256", "The download release url sha256") do |sha|
    options[:sha256] = sha
  end

  opts.on("-m", "--commit-message MESSAGE", "The message of the commit updating the formula") do |message|
    options[:message] = message.strip
  end

  opts.on_tail("-v", "--verbose", "Output more information") do
    logger.level = Logger::DEBUG
  end

  opts.on_tail("-h", "--help", "Display this screen") do
    puts opts
    exit 0
  end
end.parse!

begin
  raise "COMMIT_TOKEN environment variable is not set" unless ENV["COMMIT_TOKEN"]
  raise "missing argument: -r/--repository" unless options[:repository]
  raise "missing argument: -t/--tap" unless options[:tap]
  raise "missing argument: -f/--formula" unless options[:formula]
  raise "missing argument: -d/--download-url" unless options[:download_url]
  raise "missing argument: -s/--sha256" unless options[:sha256]

  Octokit.middleware = Faraday::RackBuilder.new do |builder|
    builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
    builder.use Faraday::Response::RaiseError
    builder.use Octokit::Middleware::FollowRedirects
    builder.use Octokit::Response::FeedParser
    builder.response :logger, logger, log_level: :debug do |logger|
      logger.filter(/(Authorization\: )(.+)/, '\1[REDACTED]')
    end
    builder.adapter Faraday.default_adapter
  end

  client = Octokit::Client.new(access_token: ENV["COMMIT_TOKEN"])

  repo = client.repo(options[:repository])

  releases = repo.rels[:releases].get.data
  raise "No releases found" unless (latest_release = releases.first)

  download_url = options[:download_url]

  tags = repo.rels[:tags].get.data
  unless (tag = tags.find { |t| t.name == latest_release.tag_name })
    raise "Tag #{latest_release.tag_name} not found"
  end

  raw_original_content = client.contents(options[:tap], path: options[:formula]).content
  original_content = Base64.decode64(raw_original_content)

  formula_name = options[:formula]
  formula_name = formula_name.chomp(".rb")
  formula_name = formula_name.gsub("Formula/", "")

  formula_desc = repo[:description]
  
  formula_proj = repo[:html_url]

  formula_sha = options[:sha256]
  
  formula_release_tag = latest_release.tag_name

  new_content = 
"class #{formula_name.capitalize()} < Formula
  desc \"#{formula_desc}\"
  homepage \"#{formula_proj}\"
  url \"#{download_url}\"
  sha256 \"#{formula_sha}\"
  license \"MIT\"
  version \"#{formula_release_tag}\"

  def install
    bin.install \"#{formula_name}\"
  end
end
"

  logger.info new_content

  blob_sha = client.contents(options[:tap], path: options[:formula]).sha

  commit_message = (options[:message].nil? || options[:message].empty?) ? "Update #{repo.name} to #{latest_release.tag_name}" : options[:message]
  logger.info commit_message
  
  client.update_contents(options[:tap],
                          options[:formula],
                          commit_message,
                          blob_sha,
                          new_content)

  logger.info "Update formula and push commit completed!"
rescue => e
  logger.fatal(e)
  exit 1
end
