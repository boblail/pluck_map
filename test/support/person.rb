class Person < ActiveRecord::Base
  has_many :books, -> { order(:title) }, as: :author
  has_many :characters, -> { order(:last_name) }, through: :books

  has_many :books_that_start_with_the, -> { order(:title) }, as: :author, class_name: "BookWithDefaultScope"
end
