# FactoryInspector

**Deprecated:** *I am not longer maintaining this little project. I recommend the wonderful [TestProf](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests) instead.*

FactoryInspector reports on where [FactoryGirl](https://github.com/thoughtbot/factory_girl) is spending its time during your test runs. While FactoryGirl is awesomely useful, overuse can lead to slow tests due to a unexpected cascade of database writes when building test objects. FactoryInspector aims to help you find where object associations might be causing cascades.

The classic problem is using `build` to keep a test entirely in memory, but not realising that object associations on the `build` may lead to multiple `create`s being invoked, slowing your 'in memory' test down unexpectedly. (Aside: [`build_stubbed`](http://robots.thoughtbot.com/use-factory-girls-build-stubbed-for-a-faster-test) is the ideal way to use FactoryGirl)

## Installation

Assuming you're using Bundler, add this line to your application's `Gemfile`:

```ruby
  group :test do
    gem 'factory_inspector'
  end
```

And then update your gems:

```shell
    $ bundle
```

## Usage

Assuming RSpec, edit `spec/spec_helper.rb`:

```ruby
  require 'factory_inspector'

  FactoryInspector.instrument
  RSpec.configure do |config|
    config.after(:suite) { FactoryInspector.results }
  end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
