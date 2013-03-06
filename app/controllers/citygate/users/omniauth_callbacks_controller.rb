# @author Zamith
# Encapsulates all the omniauth authorization logic
class Citygate::Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # Authorize user with his facebook account
  def facebook
    oauthorize "Facebook"
  end

  # Authorize user with his google (openid) account
  def google
    oauthorize "Google"
  end

  def twitter
    oauthorize "Twitter"
  end

  # In case of error renders 404
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  private

  def oauthorize(kind)
    current_user ||= (params[:user]) ? Citygate::User.find(params[:user]) : nil
    @user = find_for_oauth(kind, request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => kind
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"]
      sign_in_and_redirect @user, :event => :authentication
    else
      @user.authorizations.map(&:destroy)
      flash[:error] = @user.errors.full_messages.first
      redirect_to new_user_registration_url
    end
  end

  def find_for_oauth(provider, access_token, resource=nil)
    user, email, name, uid, auth_attr = nil, nil, nil, {}
    case provider
    when "Facebook"
      uid = access_token['uid']
      email = access_token['extra']['raw_info']['email']
      auth_attr = {
        :uid => uid,
        :token => access_token['credentials']['token'],
        :secret => nil,
        :name => access_token['extra']['raw_info']['name'],
        :link => access_token['extra']['raw_info']['link'],
        :image_url => access_token['info']['image']
      }
    when "Google"
      uid = access_token['uid']
      email = access_token['info']['email']
      auth_attr = {
        :uid => uid,
        :token => access_token['credentials']['token'],
        :secret => nil,
        :name => access_token['info']['name'],
      }
    when "Twitter"
      uid = access_token['extra']['raw_info']['id']
      name = access_token['extra']['raw_info']['name']
      auth_attr = {
        :uid => uid,
        :token => access_token['credentials']['token'],
        :secret => nil,
        :name => access_token['extra']['raw_info']['name'],
        :image_url => access_token['extra']['raw_info']['profile_image_url']
      }
    else
      raise "Provider #{provider} not handled"
    end
    if resource.nil?
      if email
        user = find_for_oauth_by_email(email, resource)
      elsif uid && name
        user = find_for_oauth_by_uid(uid, resource)
        if user.nil?
          user = find_for_oauth_by_name(name, resource)
        end
      end
    else
      user = resource
    end
    auth = user.authorizations.find_by_provider(provider)
    auth ||= user.authorizations.build(:provider => provider)
    auth.update_attributes auth_attr

    #TODO: Add config for this
    user.update_attributes(
      role_id: 1,
      confirmed_at: Time.now
    )

    return user
  end

  def find_for_oauth_by_uid(uid, resource=nil)
    user = nil
    if auth = Citygate::Authorization.find_by_uid(uid.to_s)
      user = auth.user
    end
    return user
  end

  def find_for_oauth_by_email(email, resource=nil)
    if user = Citygate::User.find_by_email(email)
      user
    else
      user = Citygate::User.new(:email => email, :password => Devise.friendly_token[0,20])
      user.save
    end
    return user
  end

  def find_for_oauth_by_name(name, resource=nil)
    if user = Citygate::User.find_by_first_name(name)
      user
    else
      user = Citygate::User.new(:first_name => name, :password => Devise.friendly_token[0,20], :email => "#{UUIDTools::UUID.random_create}@host.com")
      user.save
    end
    return user
  end
end
