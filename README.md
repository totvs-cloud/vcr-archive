# VCR::Archive [![Build Status](https://travis-ci.org/everypolitician/vcr-archive.svg?branch=master)](https://travis-ci.org/everypolitician/vcr-archive)

Using this gem causes VCR to record all HTTP interactions into separate files in a predictable directory structure. This allows you to maintain an archive of HTTP responses. It also stores the response body in a separate file for easier diffing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vcr-archive'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install vcr-archive
```

## Usage

```ruby
# code omitted
require 'vcr/archive'

VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_serializers[:vcr_archive] = VCR::Archive::Serializer
  config.cassette_persisters[:vcr_archive] = VCR::Archive::Persister
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:uri, :body, :headers],
    serialize_with: :vcr_archive,
    persist_with: :vcr_archive
  }
end

VCR.use_cassette('cassete_name_here') do
  # code omitted
end
# code omitted
```

After running this the response from http://example.org/ will be archived into the directory given as an argument to `VCR.use_cassette`.

## Development

```sh
make
```

```sh
docker-compose run vcr-archive
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/vcr-archive.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
