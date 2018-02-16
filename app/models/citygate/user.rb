module Citygate

  # @author Zamith
  # @!attribute name
  #   @return [String] the name of the user
  # @!attribute email
  #   @return [String] the email of the user
  class User < ActiveRecord::Base
    include Gravatar

    # @!group Devise configurations
    devise :database_authenticatable, :registerable, :encryptable,
      :rememberable, :trackable, :validatable, :confirmable, :omniauthable

    devise  :encryptor => :sha1
    # @!endgroup

    attr_accessible :first_name, :last_name, :email, :password, :password_confirmation, :remember_me, :confirmed_at, :role_id, :username

    has_many :authorizations, :dependent => :destroy
    belongs_to :role

    validates :username, uniqueness: true

    before_create :check_no_of_users

    def method_missing(method_name, *args, &block)
      if method_name.to_s =~ /^is_(.*)\?$/ && Citygate::Role.underscored_role_names.include?($1)
        self.class.send :define_method, method_name do
          if self.role
            self.role.name.underscore == method_name.to_s.match(/is_(.*)\?/)[1]
          else
            false
          end
        end
        self.send method_name
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      if method_name.to_s =~ /^is_(.*)\?$/ && Citygate::Role.underscored_role_names.include?($1)
        true
      else
        super
      end
    end

    # Get the json object for an user. Used by to_json.
    # @example
    #   {
    #     "email": "user@example.com",
    #     "name": "First User",
    #     "link": null,
    #     "image": "https://secure.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af.png/rating=g"
    #   }
    # @return [Hash] the json object in the form of an hash
    def as_json(options = {})
      authorization = self.authorizations.first
      {
        email: email,
        name: first_name || (authorization.name if authorization),
        link: (authorization.link if authorization),
        image: (authorization.image_url if authorization) || self.gravatar_url
      }
    end

    # Get the name if it is present or else get the email
    # @return [String] the name or email of the user
    def name_or_email
       self.full_name || self.email
    end

    # Get the user's full name (the concatenation of his first and last names)
    # @return [String] the user's full name
    def full_name
      name = "#{self.first_name} #{self.last_name}".strip
      (name.blank?) ? nil : name
    end

    # Alias for name_or_email
    def to_s
      self.name_or_email
    end

    private

    def check_no_of_users
      if Citygate::Engine.no_of_users > 0 && Citygate::User.count >= Citygate::Engine.no_of_users
        self.errors.add(:base,I18n::t('users.errors.too_many'))
        return false
      else
        return true
      end
    end
  end
end
