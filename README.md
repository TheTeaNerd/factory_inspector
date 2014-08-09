# FactoryInspector

FactoryInspect reports on where [FactoryGirl](https://github.com/thoughtbot/factory_girl) is spending time during your test runs. While FactoryGirl is useful, overuse can lead to slow tests due to a unexpected cascade of database writes when building test objects.

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

    config.before :suite do
      factory_inspector.start_inspection
    end

    config.after :suite do
      FactoryInspector.generate_report
    end
  end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
