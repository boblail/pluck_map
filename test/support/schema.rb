ActiveRecord::Schema.define(:version => 1) do

  create_table "books", :force => true do |t|
    t.string :title
    t.integer :author_id
    t.string :author_type
    t.timestamps
  end

  create_table "books_characters", :id => false, :force => true do |t|
    t.integer :book_id, null: false
    t.integer :character_id, null: false
  end

  create_table "characters", :force => true do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table "isbns", :force => true do |t|
    t.string :number
    t.integer :book_id
  end

  create_table "people", :force => true do |t|
    t.string :first_name
    t.string :last_name
    t.timestamps
  end

end
