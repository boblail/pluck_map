class Person < ActiveRecord::Base
  has_many :books, -> { order(:title) }, as: :author
  has_many :characters, -> { order(:last_name) }, through: :books
end
