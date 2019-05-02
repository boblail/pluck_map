## v0.5.0 (2019 May 1)

* REFACTOR: Introduced a new syntax for defining PluckMap Presenters and deprecated
  calling `PluckMap::Presenter.new` with a block
* FEATURE: Add `to_json` presenter method (@boblail)
* FEATURE: Add `to_csv` presenter method (@boblail)

## v0.4.1 (2019 Apr 26)

* FIX: Use `PluckMap::NullLogger` when `Rails.logger` is `nil` (@boblail)

## v0.4.0 (2019 Apr 16)

* REFACTOR: Introduced several DEPRECATION WARNINGs that will be harvested in v1.0.0 (@boblail)
* REFACTOR: Changed the implementation of the private method `selects` (@boblail)

## v0.3.0 (2019 Apr 7)

* IMPROVEMENT: Add support for MySQL (@boblail)

## v0.2.1 (2018 Mar 29)

* FIX: Allow static values to be falsey (@kobsy)

## v0.2.0 (2018 Mar 28)

* FIX: Allow static values to be falsey (@kobsy)

## v0.1.0 (2015 Nov 7)

* Initial version (@boblail)
