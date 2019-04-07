# PluckMap::Presenter

[![Gem Version](https://badge.fury.io/rb/pluck_map.svg)](https://rubygems.org/gems/pluck_map)
[![Build Status](https://travis-ci.org/boblail/pluck_map.svg)](https://travis-ci.org/boblail/pluck_map)

This library provides a DSL for presenting ActiveRecord::Relations without instantiating ActiveRecord models. It is useful when a Rails controller action does little more than fetch several records from the database and present them in some other data format (like JSON or CSV).

Suppose you have an action like this:

```ruby
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)

    render json: messages.map { |message|
      { id: message.id,
        postedAt: message.created_at,
        text: message.text } }
  end
```

This instantiates a `Message` for every result, gets the attributes out of it, and then immediately discards it.

We can skip that unnecessary instantiation by using `pluck`:

```ruby
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)

    render json: messages.pluck(:id, :created_at, :text)
      .map { |id, created, text|
        { id: id,
          postedAt: created_at,
          text: text } }
  end
```

This tends to be about one order of magnitude faster the first example.

It is straightforward but verbose (we repeat the attribute names at least three times) and changing a block like this produces noisy diffs:

```diff
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)
-   render json: messages.pluck(:id, :created_at, :text)
+   render json: messages.pluck(:id, :created_at, :text, :channel)
-     .map { |id, created, text|
+     .map { |id, created, text, channel|
        { id: id,
          postedAt: created_at,
-         text: text } }
+         text: text,
+         channel: channel } }
  end
```

And when we're presenting large or complex objects, the list of attributes we send to `pluck` or arguments we declare in the `map` block can get unwieldy!

The `PluckMap::Presenter` is simply a shorthand for generating the above pluck-map pattern. Using it, we could write our example like this:

```ruby
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)
    presenter = PluckMap::Presenter.new do |q|
      q.id
      q.postedAt select: :created_at
      q.text
      q.channel
    end
    render json: presenter.to_h(messages)
  end
```

Using that definition, `PluckMap::Presenter` dynamically generates a `.to_h` method that is implemented exactly like the example above that uses `.pluck` and `.map`.

This DSL also makes it easy to make fields optional:

```diff
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)
    presenter = PluckMap::Presenter.new do |q|
      q.id
      q.postedAt select: :created_at
      q.text
-     q.channel
+     q.channel if params[:fields] =~ /channel/
    end
    render json: presenter.to_h(messages)
  end
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem "pluck_map"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pluck_map


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boblail/pluck_map.
