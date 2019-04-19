# PluckMap::Presenter

[![Gem Version](https://badge.fury.io/rb/pluck_map.svg)](https://rubygems.org/gems/pluck_map)
[![Build Status](https://travis-ci.org/boblail/pluck_map.svg)](https://travis-ci.org/boblail/pluck_map)

This library provides a DSL for presenting ActiveRecord::Relations without instantiating ActiveRecord models. It is useful when a Rails controller action does little more than fetch several records from the database and present them in some other data format (like JSON or CSV).


### Table of Contents

- [Why PluckMap?](#why-pluckmap)
- Usage
  - [Defining attributes to present](#defining-attributes-to-present)
  - [Relationships](#relationships)
  - [Presenting Records](#presenting-records)
- [Installation](#installation)
- [Requirements](#requirements)
- [Development & Contributing](#development)


## Why PluckMap?

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

:point_up: This instantiates a `Message` for every result, gets the attributes out of it, and then immediately discards it.

We can skip that unnecessary instantiation by using [`pluck`](https://api.rubyonrails.org/classes/ActiveRecord/Calculations.html#method-i-pluck):

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

In [a simple benchmark](https://github.com/boblail/pluck_map/blob/master/test/benchmarks.rb), the second example is 3× faster than the first and allocates half as much memory. :rocket: (Mileage may vary, of course, but in real applications with more complex models, I've gotten more like a 10× improvement at bottlenecks.)

One drawback to this technique is its verbosity — we repeat the attribute names at least three times and changes to blocks like this make for noisy diffs:

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

`PluckMap::Presenter` gives us a shorthand for generating the above pluck-map pattern. Using it, we could write our example like this:

```ruby
  def index
    messages = Message.created_by(current_user).after(3.weeks.ago)
    presenter = PluckMap[Message].define do |q|
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
    presenter = PluckMap[Message].define do |q|
      q.id
      q.postedAt select: :created_at
      q.text
-     q.channel
+     q.channel if params[:fields] =~ /channel/
    end
    render json: presenter.to_h(messages)
  end
```

### How is this different from [Jbuilder](https://github.com/rails/jbuilder)?

Jbuilder gives you a similar DSL for defining JSON to be presented but it operators on instances of ActiveRecord objects rather than producing a query to pluck just the values we need from the database.



## Usage

### Defining Attributes to Present

#### Syntax

Define attributes using either of these syntaxes:

 1. Without the block variable

    ```ruby
    presenter = PluckMap[Book].define do
      title
    end
    ```

 2. With the block variable

    ```ruby
    presenter = PluckMap[Book].define do |q|
      q.title
    end
    ```

Apart from the repetition of the block variable, the difference between the two styles is the value of `self` within the block. In the first case, `self` will be `PluckMap::AttributesBuilder`. In the second, `self` will be the containing object. The former is less repetitious but the latter can be useful if you want to refer to local methods or instance variables in the context.

#### `:as` and `:select`

:point_down: This will construct a query to select `books.title` from the database and present the value of each title with the key (or column name) `"title"`:

```ruby
presenter = PluckMap[Book].define do
  title
end
```

There are two ways to change the name of the key that is presented. Both of the following examples will select `authors.first_name` from the database and present it as `"firstName"`:


 1. Using `:as`

    ```ruby
    presenter = PluckMap[Author].define do
      first_name as: "firstName"
    end
    ```

 2. Using `:select`

    ```ruby
    presenter = PluckMap[Author].define do
      firstName select: :first_name
    end
    ```

You can also pass raw SQL expressions to `:select`:

```ruby
presenter = PluckMap[Person].define do
  name select: Arel.sql("CONCAT(first_name, ' ', last_name)")
end
```

#### `:map`

In the example above, we constructed `name` from `first_name` and `last_name` with a SQL expression. There are many reasons why we might want to process values before presenting them. When possible, it's usually more efficient to do this work in the query itself, but there are times when it's necessary or expedient to do it in Ruby. Use `:map` to process values returned from the query before they are presented.

Here are a couple of examples:

- Constructing `"name"` with `:map`:
    ```ruby
    presenter = PluckMap[Person].define do
      name select: %i[ first_name last_name ], map: ->(first, last) { "#{first} #{last}" }
    end
    ```

- Formatting phone numbers with `:map`:
    ```ruby
    presenter = PluckMap[Person].define do
      phoneNumber select: %i[ phone_number ], map: ->(number) { PhoneNumberFormatter.format(number) }
    end
    ```

#### `:value`

You can also hard-code a value to be used and it won't be queried from the database. There are two ways of expressing this:

```ruby
presenter = PluckMap[Person].define do
  id
  type "Person"
end
```

```ruby
presenter = PluckMap[Person].define do
  id
  type value: "Person"
end
```

### Relationships

PluckMap can also describe nested data. There are two special methods in the `define` block that introduce child resources:

 1. `has_one` will treat the resource as a nested object or null
 2. `has_many` will treat the resource as an array of nested objects (which may be empty)

The first argument to either of these methods is the name of an association on the presented model.

You can use either of these methods with any kind of ActiveRecord relation (`belongs_to`, `has_one`, `has_many`, `has_and_belongs_to_many`), although it generally makes more sense to use `has_one` with Rails' singular associations and `has_many` with Rails' plural associations.

#### `has_one`

In the example below, assume

```ruby
class Book < ActiveRecord::Base
  belongs_to :author
end
```

This presenter :point_down: selects the title of every book as well as its author's name:

```ruby
presenter = PluckMap[Book].define do
  title
  has_one :author do
    name
  end
end
```

(We can also write it using block variables, if that's easier to read.)

```ruby
presenter = PluckMap[Book].define do |book|
  book.title
  book.has_one :author do |author|
    author.name
  end
end
```

Attributes defined for a relationship support all the same features as [attributes defined at the root level](#defining-attributes-to-present).


#### `has_many`

We can present the reverse of the above example with `has_many`. This example will select a list of authors and, for each, a list of the books they wrote:

```ruby
presenter = PluckMap[Author].define do
  name
  has_many :books do
    title
  end
end
```

#### scopes

An optional second argument to both `has_one` and `has_many` is a scope block that you can use to modify the query that would select the associated records. You can use any of ActiveRecord's standard [querying methods](https://guides.rubyonrails.org/active_record_querying.html) inside the scope block.

In this example, we've altered our last presenter to ensure that books are listed alphabetically:

```ruby
presenter = PluckMap[Author].define do
  name
  has_many :books, -> { order(title: :asc) } do
    title
  end
end
```


### Presenting Records

#### `:to_h`

Once you've defined a presenter, pass an `ActiveRecord::Relation` to `to_h` to get an array of hashes:

```ruby
presenter = PluckMap[Person].define do
  id
  type value: "Person"
end

presenter.to_h(Person.where(id: 1)) # => [{ id: 1, type: "Person" }]
```

#### `:to_json` and `:to_csv`

You can `.map` that array to construct whatever document you need, but PluckMap implements two methods that are optimized for generating JSON and CSV:

```ruby
presenter.to_json(Person.where(id: 1)) # => '[{"id":1,"type":"Person"}]'
presenter.to_csv(Person.where(id: 1)) # => "id,type\n1,Person"
```

#### Custom Presenters

You can define new (or override existing) presenter methods by mixing modules into `PluckMap::Presenter`. Here's an example of how you might create a presenter that produces an Excel document using an imaginary `Excel::Document` library:

```ruby
module PluckToXlsxPresenter
  def to_excel(query)
    # Every presenter method accepts an ActiveRecord::Relation
    # and passes it to `pluck` which yields the results.
    pluck(query) do |results|

      # Use an imaginary Excel gem that has an Excel::Document object
      spreadsheet = Excel::Document.new

      # Fill in a Header row
      # `attributes` is a method on `PluckMap::Presenter` that describes
      # the attributes you defined when you constructed the presenter.
      attributes.each_with_index do |attribute, i|
        spreadsheet.cell[0, i] = attribute.name
      end

      # Results is an array of rows (Rows are an array of values)
      results.each_with_index do |values, row_number|
        attributes.each_with_index do |attribute, column_number|

          # `attribute.exec` will pick the right values from the row
          # and perform any required processing.
          spreadsheet.cell[row_number + 1, column_number] = attribute.exec(values)
        end
      end

      spreadsheet.render # `pluck` returns the result of the block
    end
  end
end

PluckMap::Presenter.send :include, PluckToXlsxPresenter
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



## Requirements

The gem's only runtime requirement is:

 - [activerecord](https://rubygems.org/gems/activerecord) 4.2+

It supports these databases out of the box:

 - PostgreSQL 9.4+
 - MySQL 5.7.22+
 - SQLite 3.10.0+

(Note: the versions given above are when certain JSON aggregate functions were introduced in each supported database. `PluckMap`'s core behavior will work with earlier versions of the database above but certain features like optimizations to `to_json` and relationships require the specified versions.)



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boblail/pluck_map.
