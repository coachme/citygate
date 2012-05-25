require "rails"

require "rubygems"
require "devise"
require "devise"
require "devise_invitable"
require "devise-encryptable"
require 'omniauth'
require 'omniauth-facebook'
require 'omniauth-openid'
require 'uuidtools'
require 'will_paginate'
require 'cancan'

module Citygate
  def self.root
    File.expand_path '../../..', __FILE__
  end

  class Engine < ::Rails::Engine
    isolate_namespace Citygate
  end
end
