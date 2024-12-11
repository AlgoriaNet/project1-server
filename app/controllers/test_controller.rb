# frozen_string_literal: true

class TestController < ApplicationController
  def index
    ActionCable.server.broadcast("Battle_1", {msg: "test"})
  end
end
