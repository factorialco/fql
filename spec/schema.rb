# typed: strict
ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :name
    t.integer :age
    t.datetime :dob

    t.timestamps
  end

  create_table :addresses, force: true do |t|
    t.belongs_to :user, foreign_key: :tenant_id
    t.string :country

    t.timestamps
  end

  create_table :cities, force: true do |t|
    t.belongs_to :address
    t.string :name

    t.timestamps
  end
end

class User < ActiveRecord::Base
  has_one :address, foreign_key: :tenant_id
  has_one :city, through: :address
end

class Address < ActiveRecord::Base
  belongs_to :user, foreign_key: :tenant_id
  belongs_to :city
end

class City < ActiveRecord::Base
  has_many :addresses
end
