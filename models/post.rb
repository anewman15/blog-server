class Post < Sequel::Model
  one_to_many :comments
end
