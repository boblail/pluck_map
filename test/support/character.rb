class Character < ActiveRecord::Base
  has_and_belongs_to_many :books, inverse_of: :characters
end
