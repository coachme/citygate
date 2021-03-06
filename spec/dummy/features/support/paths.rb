module NavigationHelpers
  include Citygate::Engine.routes.url_helpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /my profile page/
      profile_path

    when /the home\s?page/
      root_path

    when /the sign up page/
      '/users/sign_up'

    when /the sign in page/
      '/users/sign_in'
      
    when /the users admin page/
      admin_users_path

    when /the user admin page/
      admin_user_path(1)
      
    when /the login page/
      root_path

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
