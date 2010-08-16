ActiveRecord::Schema.define :version => 0 do
  create_table :posts, :force => true do |t|
    t.column :title, :string
    t.column :body, :text
    t.column :visible, :boolean
  end

  create_table :sources, :force => true do |t|
    t.column :name, :string
    t.column :url, :string
    t.column :description, :text
  end
end
