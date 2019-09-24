require 'urika'

RSpec.describe Urika do
  it "has a version number" do
    expect(Urika::VERSION).not_to be nil
  end

  it 'validates uris correctly' do
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
        [ 'https://www.google.dk/amp/search/amp?q=foo+bar+baz&oq=foo+bar+baz&aqs=chrome..69i57j0l5.1283j0j7&sourceid=chrome&ie=UTF-8&utm_source=meh', 'google.dk/search?q=foo+bar+baz&oq=foo+bar+baz' ],
        [ 'Check out https://youtu.be/ZpAYnVJX9CY because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY' ],
        [ 'Check out https://youtu.be/ZpAYnVJX9CY?t=60 because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY&t=60' ],
        [ 'Check out https://youtube.com/watch?v=ZpAYnVJX9CY&t=60&feature=youtu.be because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY&t=60' ],
        [ 'Check out https://youtu.be///ZpAYnVJX9CY because why not??!', 'youtube.com/watch?v=ZpAYnVJX9CY' ],
        [ 'https://www.google.dk/amp///search//amp?q=foo+bar+baz&oq=foo+bar+baz&aqs=chrome..69i57j0l5.1283j0j7&sourceid=chrome&ie=UTF-8&utm_source=meh', 'google.dk/search?q=foo+bar+baz&oq=foo+bar+baz' ],
    ]

    uris.each { |pair| expect(Urika.get_first_url(pair[0])).to eq(pair[1]) }
  end # 'validates uris correctly'

  it 'finds multiple urls in a message' do
    messages = [
        [ 'Check out https://youtu.be/ZpAYnVJX9CY and https://youtu.be/ZpAYnVJX9CY?t=60 because why not??!', 2 ],
        [ 'Check out https://youtu.be/ZpAYnVJX9CY?t=60 because why not??!', 1 ],
        [ 'Check out youtube because why not??!', 0 ],
    ]

    messages.each{ |pair| expect(Urika.get_all_urls(pair[0]).size).to eq(pair[1]) }
  end

  it 'collapses youtube urls' do
    messages = [
      [ 'Check out https://www.youtube.com/watch?v=fT-uWOVP5q0 because why not??!', ['youtube.com/watch?v=fT-uWOVP5q0'] ],
      [ 'Check out https://youtu.be/fT-uWOVP5q0 because why not??!', ['youtube.com/watch?v=fT-uWOVP5q0'] ],
    ]
    messages.each{ |pair| expect(Urika.get_all_urls(pair[0])).to eq(pair[1]) }
  end

  it 'remaps invidious urls to youtube' do
    messages = [
        [ 'Check out https://www.invidio.us/watch?v=fT-uWOVP5q0 because why not??!', ['youtube.com/watch?v=fT-uWOVP5q0'] ],
        [ 'Check out https://invidio.us/watch?v=fT-uWOVP5q0 because why not??!', ['youtube.com/watch?v=fT-uWOVP5q0'] ],
    ]
    messages.each{ |pair| expect(Urika.get_all_urls(pair[0])).to eq(pair[1]) }
  end
end
