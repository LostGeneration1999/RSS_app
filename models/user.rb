Bundler.require

class User <ActiveRecord::Base
  ActiveRecord::Base.configurations = YAML.load_file('database.yml')
  ActiveRecord::Base.establish_connection(:development)

  has_many :urls, dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  validates :email, uniqueness: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }
  validates :email, presence: true
  validates :password_hash, confirmation: true
  validates :password_hash, presence: true
  validates :password_salt, presence: true

  def self.authenticate(email, password)
    user = self.where(email: email).first
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil 
    end 
  end 

  def encrypt_password(password)
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end 
  end
end
