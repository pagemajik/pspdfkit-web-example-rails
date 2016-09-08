class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  attr_reader :current_user
  helper_method :current_user
  before_action :require_login

  def require_login
    redirect_to new_user_path unless @current_user = User.where(id: session[:user_id]).first
  end
end
