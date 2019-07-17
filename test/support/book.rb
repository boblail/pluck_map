class Book < ActiveRecord::Base
  belongs_to :author, class_name: "Person"
  has_and_belongs_to_many :characters, inverse_of: :books
  has_one :isbn
end

class RealOrFictionalBook < ActiveRecord::Base
  self.table_name = "books"
  belongs_to :author, polymorphic: true
  has_and_belongs_to_many :characters, inverse_of: :books
  has_one :isbn
end

class BookWithDefaultScope < ActiveRecord::Base
  self.table_name = "books"
  default_scope -> { where("title like 'The%'" ) }
end
