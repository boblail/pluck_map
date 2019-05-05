class Person < ActiveRecord::Base
  has_many :books, as: :author
end
