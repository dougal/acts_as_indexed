# Acts As Indexed

This plugin allows boolean-queried fulltext search to be added to any Rails
app with no dependencies and minimal setup.

## Installation

1. Add the gem to your Gemfile:

```ruby
gem 'acts_as_indexed'
```

2. Run bundle install.

## Upgrading

When upgrading it is recommended you delete the index directory and allow it to
be rebuilt.

## Usage

### Setup

Add `acts_as_indexed` to the top of any models you want to index, along with a
list of the fields you wish to be indexed.

```ruby
class Post < ActiveRecord::Base
  acts_as_indexed fields: [:title, :body]

  # ...
end
```

The fields are not limited to model fields, but can be any instance method of
the current model.

```ruby
class User < ActiveRecord::Base
  acts_as_indexed fields: [:address, :fullname]

  def fullname
    self.firstname + ' ' + self.lastname
  end

  ...
end
```

Any of the configuration options in the "Further Configuration" section can be
added as to the `acts_as_indexed` method call. these will override any defaults
or global configuration.

you can specify a proc that needs to evaluate to true before the item gets
indexed. this is useful if you only want items with a certain state to be
included. the proc is passed the current object's instance so you are able to
test against that.

for example, if you have a visible column that is false if the post is hidden,
or true if it is visible, you can filter the index by doing:

class post < activerecord::base
acts_as_indexed fields: [:title, :body], if: proc.new { |post| post.visible? }
...
end

### Searching

#### With Relevance

to search with the most relevant matches appearing first, call the
`find_with_index` method on your model, passing a query as the first argument.
the optional `ids_only` parameter, when set to true, will return only the ids
of any matching records.

```ruby
# returns array of post objects ordered by relevance.
my_search_results = post.find_with_index('my search query')

# pass any of the activerecord find options to the search.
my_search_results = post.find_with_index('my search query', { limit: 10}) # return the first 10 matches.

# returns array of ids ordered by relevance.
my_search_results = post.find_with_index('my search query', {}, { ids_only: true }) # =>  [12,19,33...
```

#### Without Relevance (Scope)

If the relevance of the results is not important, call the `with_query` named
scope on your model, passing a query as an argument.

```ruby
# Returns array of Post objects.
my_search_results = Post.with_query('my search query')

# Chain it with any number of ActiveRecord methods and named_scopes.
my_search_results = Post.public.with_query('my search query').find(:all, limit: 10) # return the first 10 matches which are public.
```

### Query Options

The following query operators are supported:

- AND :: This is the default option. 'cat dog' will find records matching 'cat'
  AND 'dog'.
- NOT :: 'cat -dog' will find records matching 'cat' AND NOT 'dog'
- INCLUDE :: 'cat +me' will find records matching 'cat' and 'me', even if 'me'
  is smaller than the `min_word_size`
- "" :: Quoted terms are matched as phrases. '"cat dog"' will find records
  matching the whole phrase. Quoted terms can be preceded by the NOT operator;
  'cat -"big dog"' etc. Quoted terms can include words shorter than the
  `min_word_size`.
- ^ :: Terms that begin with ^ will match records that contain a word starting
  with the term. '^cat' will find matches containing 'cat', 'catapult',
  'caterpillar' etc.
- ^"" :: A quoted term that begins with ^ matches any phrase that begin with
  this phrase. '^"cat d"' will find records matching the whole phrases "cat
  dog" and "cat dinner". This type of search is useful for autocomplete inputs.

### Pagination

#### With Relevance

Pagination is supported via the `paginate_search` method whose first argument
is the search query, followed by all the standard will_paginate arguments.

```ruby
@images = Image.paginate_search('girl', page: 1, per_page: 5)
```

#### Without Relevance (Scope)

Since `with_query` is a named scope, WillPaginate can be used in the normal
fashion.

```ruby
@images = Image.with_query('girl').paginate(page: 1, per_page: 5)
```

### Further Configuration

A config block can be provided in your environment files or initializers.
Example showing changing the min word size:

```ruby
ActsAsIndexed.configure do |config|
  config.min_word_size = 3
  # More config as required...
end
```

A full rundown of the available configuration options can be found in
`lib/acts_as_indexed/configuration.rb`

## Caveats

Acts as Indexed is intended to provide a simple solution to full text search
for modest-sized application setups. As a result it comes with some operational
caveats:

- Only works with ASCII characters as does not fold/normalise UTF-8 characters.
  A workaround for this is [described in this
  Gist](https://gist.github.com/193903bb4e0d6e5debe1)
- Is not multi-process safe. If two processes write to the index at the same
  time, the index will likely end up in an inconsistent state.
- Multiple servers (containers, Heroku Dynos, etc) will maintain their own copy
  of the index. These will get out of sync as write operations occur. Use of a
  shared filesystem prevents this.

## RDoc Documentation

View the rdoc documentation
online at [Rdoc.info](http://rdoc.info/projects/dougal/acts_as_indexed/).

## Problems, Comments, Suggestions?

Open a Github issue. If you have contribution you would like to make, please
discuss in a Github Issue prior to submitting a pull request.

## Contributors

A huge thanks to all the contributors to this library. Without them many
bugfixes and features wouldn't have happened.

- Douglas F Shearer - http://douglasfshearer.com
- Thomas Pomfret
- Philip Arndt
- Fernanda Lopes
- Alex Coles
- Myles Eftos
- Edward Anderson
- Florent Guilleux
- Ben Anderson
- Theron Toomey
- Uģis Ozols
- Gabriel Namiman
- Roman Samoilov
- David Turner
- Pascal Hurni
- Ryan Kopf
