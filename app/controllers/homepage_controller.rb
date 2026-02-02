# frozen_string_literal: true

class HomepageController < ApplicationController
  def index
    # Landing page shows without authentication
    # Authentication is triggered when user clicks "Start now"
    # which redirects to the identity service
    @hide_auth_banner = true
  end
end
