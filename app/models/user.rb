class User < ActiveRecord::Base
  include Gravtastic
  has_gravatar

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:twitter]

  has_many :squeeks, :inverse_of => :user
  has_many :relationships, foreign_key: "consumer_id"
  has_many :reverse_relationships, foreign_key: "broadcaster_id", class_name: "Relationship"
  has_many :broadcasters, through: :relationships, source: :broadcaster
  has_many :consumers, through: :reverse_relationships, source: :consumer

  def self.find_for_database_authentication(conditions)
    self.where(:username => conditions[:email]).first || self.where(:email => conditions[:email]).first
  end

  def self.find_for_twitter_oauth(auth)
    where(auth.slice(:provider, :uid)).first_or_create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.username = "@#{auth.info.nickname}"
        user.password = Devise.friendly_token[0,20]
    end
  end

  def consuming?(broadcaster)
    relationships.find_by(broadcaster_id: broadcaster.id)
  end

  def consume!(broadcaster)
    relationships.create!(broadcaster_id: broadcaster.id)
  end
end
