class UsersController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    user = User.find_or_create_by!(name: params.require(:user).require(:name).downcase)
    session[:user_id] = user.id
    redirect_to root_path
  end
end