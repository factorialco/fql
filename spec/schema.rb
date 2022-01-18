# typed: strict
ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.string :name
    t.integer :age
    t.datetime :dob

    t.timestamps
  end

  create_table :addresses, :force => true do |t|
    t.belongs_to :user, foreign_key: :tenant_id
    t.string :country

    t.timestamps
  end
end
