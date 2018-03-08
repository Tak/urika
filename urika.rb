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

class Urika
  URIRE = /https?:\/\/[^\s]+/
  YOUTUDOTBERE = /^youtu.be\/(?<video>[\w\d]+)(\?(?<query>.*))?/

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
    sanitized.gsub!(/\/amp(\/)?/, '\1') # fuck amp
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
    return nil unless (match = URIRE.match(message))

    uri = URI.parse(match.to_s())
    return (uri && (uri.kind_of?(URI::HTTP) || uri.kind_of?(URI::HTTPS))) ? sanitize(uri) : nil
  end # get_first_url
end

if (__FILE__ == $0)
  require 'test/unit'

  class UrikaTest < Test::Unit::TestCase
    def setup()
    end # setup

    def test_uri_validation
      uris = [
          [ 'http://google.com', 'google.com' ],
          [ 'https://google.com/', 'google.com' ],
          [ 'htp://google.com', nil ],
          [ 'ftp://google.com', nil ],
          [ 'I would like you to see http://google.com', 'google.com' ],
          [ 'I would like you to see https://google.com', 'google.com' ],
          [ 'I would like you to see htp://google.com', nil ],
          [ 'I would like you to see ftp://google.com', nil ],
          [ 'htp://google.com https://google.com ttp://google.com', 'google.com' ],
          [ 'htp://google.com http://google.com/amp?redirect_source=google.com', 'google.com' ],
          [ 'https://www.google.dk/amp/search/amp?q=foo+bar+baz&oq=foo+bar+baz&aqs=chrome..69i57j0l5.1283j0j7&sourceid=chrome&ie=UTF-8&utm_source=meh', 'www.google.dk/search?q=foo+bar+baz&oq=foo+bar+baz' ],
          [ 'Check out https://youtu.be/ZpAYnVJX9CY because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY' ],
          [ 'Check out https://youtu.be/ZpAYnVJX9CY?t=60 because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY&t=60' ],
          [ 'Check out https://youtube.com/watch?v=ZpAYnVJX9CY&t=60&feature=youtu.be because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY&t=60' ],
      ]

      uris.each { |pair|
        url = Urika.get_first_url(pair[0])
        assert_equal(pair[1], url, "Unexpected url #{url} for input #{pair[0]}")
      }
    end # test_uri_validation
  end
end
