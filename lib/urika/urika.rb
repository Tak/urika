#!/usr/bin/env ruby
# encoding: utf-8

# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

require 'uri'

module Urika
  URIRE = /https?:\/\/[^\s><]+/
  YOUTUDOTBERE = /^youtu.be\/(?<video>[\w\d-]+)(\?(?<query>.*))?/

  # youtu.be/meh => youtube.com/watch?v=meh
  def self.expand_youtudotbe(uri_string)
    match = YOUTUDOTBERE.match(uri_string)
    return uri_string unless match

    captures = match.names.zip(match.captures).to_h()
    return "youtube.com/watch?v=#{captures['video']}"
  end

  def self.sanitize(uri)
    # Probably suboptimal performance
    sanitized = "#{uri.host}#{uri.path}"
    sanitized.gsub!(/^www\./i, '') # strip leading "www."
    sanitized.gsub!(/\/amp(\/)?/, '\1') # fuck amp
    sanitized.gsub!(/\/+/, '/') # collapse adjacent slashes
    sanitized.gsub!(/\/$/, '') # strip trailing slash for consistency between posters
    sanitized = expand_youtudotbe(sanitized)
    return sanitized unless uri.query

    queryJoiner = /\?/.match(sanitized) ? '&' : '?'
    query = uri.query
    query.gsub!(/&?utm_[\w]+=[^&]*/, '') # utm_whatever is irrelevant
    query.gsub!(/&?(aqs|sourceid|ie|redirect_source|feature)=[^&]*/, '') # don't care about these either
    return uri.query.empty? ? sanitized : "#{sanitized}#{queryJoiner}#{query}"
  end

  # Gets the first http[s] url from a string
  # param message The string to be searched
  # returns The first url (sanitized), or nil
  def self.get_first_url(message)
    urls = get_all_urls(message)
    urls.empty? ? nil : urls[0]
  end # get_first_url

  def self.get_all_urls(message)
    return [] if !message
    urls = message.scan(URIRE)
    return [] if !urls

    urls.inject([]) do |memo, url|
      uri = URI.parse(url)
      if uri && (uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS))
        memo << sanitize(uri)
      else
        memo
      end
    end
  end
end
