# Changelog

## 0.9.0 [25 August 2023]

Thanks to Ryan Kopf for reviewing PRs, fixing the broken CI, and tidying things up to make this release possible.

- Now tested on Ruby 3.0 and Ruby 3.1. [#70](https://github.com/dougal/acts_as_indexed/pull/70). [[ryankopf](https://github.com/ryankopf) - Ryan Kopf]
- Remove deprecated Fixnum references. [#62](https://github.com/dougal/acts_as_indexed/pull/62). [[yez](https://github.com/yez) - Jake Yesbeck]
- Delete Gemfile.lock from repo. [#68](https://github.com/dougal/acts_as_indexed/pull/68). [[parndt](https://github.com/parndt) - Philip Arndt]
- Bump i18n from 0.6.1 to 0.9.5. [#64](https://github.com/dougal/acts_as_indexed/pull/64)
- Bump tzinfo from 0.3.35 to 0.3.61. [#66](https://github.com/dougal/acts_as_indexed/pull/66)
- Bump will_paginate from 3.0.3 to 3.0.5. [#67](https://github.com/dougal/acts_as_indexed/pull/67)

## 0.8.3 [17 February 2013]

- Now tested on Ruby 2.0.
- Fixed issue where underscores were not stripped by the pre-tokenizer.

## 0.8.2 [27 January 2013]

- Full review and update of test examples.
- Fixed bug where all records matching resulted in an ID rather than scored order. [phurni - Pascal Hurni]
- Fixed bug where records were returned in order of lowest-score first. [phurni - Pascal Hurni]
- Fixed bug where 1.8.7 would fail CI tests. [parndt - Philip Arndt]
- 70x performance improvement for non-changed record updates.
- Added a benchmark suite.
- Updated README install instructions. [gudata - Ivaylo Bardarov]

## 0.8.1 [21 December 2012]

- Fixed bug where record count was not correctly updated on bulk add. [phurni - Pascal Hurni]

## 0.8.0 [20 December 2012]

- Fixed bug where intentional hyphenation was treated as a negative query. Fixes #31.
- Fixed bug where will_paginate_search was not being required. Fixes #23.
- Fixed bug where quoted phrases were matched across field boundaries. [novalis - David Turner]
- Fixed bug where records with indentical match-rankings were returned in different orders under different Ruby implementations.
- Storage is now process and thread-safe. Fixes issue #34. [rsamoilov - Roman Samoilov]
- Added configuration option to force is-Windows mode for storage. Fixes issues #32, #39.
- Added multiple Gemfiles for Travis CI. https://travis-ci.org/dougal/acts_as_indexed
- Acts as Indexed can now be tested stand-alone without a generated Rails app.
- ModelKlass.build_index is now a public method.

## 0.7.8 [14 March 2011]

- Fixed bug with file renaming on Windows. Fixes issue #21. [gabynamiman - Gabriel Namiman]

## 0.7.7 [14 November 2011]

- Fixed bug with out-of-date indexes on Windows. Fixes issue #20. [parndt - Philip Arndt]

## 0.7.6 [24th October 2011]

- Removed support for atomic writes under Windows. Fixes issue #15.

## 0.7.5 [14th October 2011]

- Screwup fix release.

## 0.7.4 [13th October 2011]

- Default index location is now in tmp directory. [parndt - Philip Arndt]
- Fixed a bug where namespaced models would have directory names containing colons. [ugisozols - Uģis Ozols]

## 0.7.3 [3rd July 2011]

- Support for non-default primary keys. [ttoomey - Theron Toomey]
- Fixed issue with file-locking on JRuby. [banderso - Ben Anderson]

## 0.7.2 [31st March 2011]

- Fixed bug with ranking of records [Christopher Souvey - bug report]
- Fixed a bug with the slicing of records before AR order is applied. [Christopher Souvey - bug report]
- Fixed bug with slicing of id-only results.
- Error now raised when combining ids_only with find options other than limit and offset.
- Can now disable auto-indexing. Useful for large test suites.

## 0.7.1 [22nd February 2011]

- Removed file locking on Microsoft Windows as it is unsupported.

## 0.7.0 [11th February 2011]

- Threadsafe support. Index files are now locked for changes, and atomically written.
- Configurable case-sensitivity.
- Improved performance of index builds.
- Now warns on old version of the index.
- Upgrade instructions added to README. [ionas - Florent Guilleux]

## 0.6.7 [7th February 2011]

- find_by_index and paginate_search are no longer deprecated.
- Improved documentation.
- Storage is now its own class to allow future development of locking and pluggable backends.

## 0.6.6 [31st August 2010]

- Now Heroku compatible out of the box, index is created in tmp when root dir is non-writable. [parndt - Philip Arndt - Great suggestion]
- Fixed a require path issue on 1.9.2.
- Fixed an issue with index_file location on Rails 3.0.0 final.

## 0.6.5 [19th August 2010]

- Reintroduced support for older version of Ruby which do not implement Array#exclude? [bug report by Andy Eggers]
- Using Bundler to manage development dependencies.

## 0.6.4 [16th August 2010]

- Added starts-with query type [nilbus - Edward Anderson]
- Various fixes and improvements.
- Real names given for all contributors.

## 0.6.3 [5th July 2010]

- Index file path can now be defined as a Pathname as well as an array. [parndt - Philip Arndt]
- Can now define which records are indexed and which are not via an :if proc. [madpilot - Myles Eftos]
- Lots of tidying up. [parndt - Philip Arndt]
- Rails 3 fixes. [myabc - Alex Coles]

## 0.6.2 [11th June 2010]

- Now available as a Gem as well as the original plugin. [parndt - Philip Arndt - Thanks for doing most of the hard work.]

## 0.6.0 [10th June 2010]

- Now supports Rails 3.x.x as well as Rails 2.x.x.
- Added global configuration options.
- Now recommending using with_query scope for searching.
- Deprecated find_with_index and will_paginate_search methods.

## 0.5.3 [6th June 2010]

- Now supports non-standard table names automatically. [nandalopes - Fernanda Lopes]

## 0.5.2 [3rd May 2010]

- Fix for Errno::ERANGE error related to certain Math.log calculations. [parndt - Philip Arndt]
- Improved index detection in a shared-directory environment. [bob-p - Thomas Pomfret]

## 0.5.1 [11 June 2009]

- Fixed Ruby 1.8.6 compatibility.

## 0.5.0 [24 April 2009]

- Ruby 1.9 and Rails 2.3 compatibility.
- Index location can now be set. Provides Heroku compatibility.
- Better errors on bad options.
- ActiveRecord order argument overrides ranking returned by find_by_index.
- Various test environment improvements
- Various Bugfixes

## 0.4.6 [10 August 2008]

- Rolled in pagination.

## 0.4.5 [04 February 2008]

- Fixed a bug where the find_options :limit would be added to the :offset, which caused incorrectly sized collections to be returned.
- Fixed an 'ambiguous column' error when using the :includes find_options key.

## 0.4.4 [29 November 2007]

- Fixed a bug causing the weighting section of the code to error out.

## 0.4.3 [27 September 2007]

- Fixed a bug causing records to be deleted from index during record updates.

## 0.4.2 [27 September 2007]

- Fixed a bug causing identically ranked records to be lost.

## 0.4.1 [22 September 2007]

- Fixed a bug in the main search method.

## 0.4.0 [22 September 2007]

- Search results now ranked by relevance.

## 0.3.3 [20 September 2007]

- Fixed index update bug where deleted atoms were not removed from index.
- Improved performance of quoted queries.
- Improved performance of index updates.
- When building a full index, records are retrieved and indexed in batches to reduce memory consumption.

## 0.3.2 [19 September 2007]

- Fixed index update bug.

## 0.3.1 [18 September 2007]

- Added RDoc documentation comments.

## 0.3.0 [18 September 2007]

- Minor bug fixes.
- min_word_size now works properly, with queries containing small words in
  quotes or being preceded by a '+' symbol are now searched on.

## 0.2.2 [06 September 2007]

- Search now caches query results within a session. Call the search twice in an
  action? Only runs once!

## 0.2.1 [05 September 2007]

- AR find options can now be passed to the search to allow finer control of
  returned Model Objects.

## 0.2.0 [04 September 2007]

- Major performance improvements.
- Index segmentation can now be tuned.

## 0.1.1 [31 August 2007]

- Added a full set of tests.
- Fixed various set-manipulation based errors.
- Fixed a bug when searching for quoted phrases.

## 0.1.01 [31 August 2007]

- Fixed a casting bug occurring when adding non-string fields to the index.

## 0.1 [31 August 2007]

- Initial release.
