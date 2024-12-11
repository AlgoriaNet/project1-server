class UsersController < ApplicationController
  def register
    user = User.new(user_params)

    if user.save
      render json: { message: 'Registration successful', user: { id: user.id, email: user.email } }, status: :created
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end
end
