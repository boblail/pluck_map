ActiveRecord::Schema.define(:version => 1) do

  create_table "authors", :force => true do |t|
    t.string :first_name
    t.string :last_name
    t.timestamps
  end

  create_table "books", :force => true do |t|
    t.string :title
    t.integer :author_id
    t.timestamps
  end

end
