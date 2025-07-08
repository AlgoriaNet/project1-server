#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Run the migration
ActiveRecord::Migration.verbose = true

# Define the migration class
class AddEnergyClaimFieldsToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :daily_energy_claims, :json
    add_column :players, :last_energy_claim_date, :date
  end
end

# Check if migration has already been run
unless ActiveRecord::Base.connection.column_exists?(:players, :daily_energy_claims)
  puts "Running migration: AddEnergyClaimFieldsToPlayers"
  migration = AddEnergyClaimFieldsToPlayers.new
  migration.migrate(:up)
  puts "Migration completed successfully!"
else
  puts "Migration already applied - daily_energy_claims column exists"
end
