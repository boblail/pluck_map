ActiveRecord::Schema.define(:version => 1) do

  create_table "authors", :force => true do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table "books", :force => true do |t|
    t.string :title
    t.integer :author_id
  end

end
