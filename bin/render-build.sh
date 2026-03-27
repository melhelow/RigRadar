#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
bundle exec rake import:truckstops_verified[lib/csvs/truck_stops_verified.csv]
FILE=lib/csvs/NTAD_Truck_Stop_Parking.csv bundle exec rake import:rest_areas
FILE=lib/csvs/NTAD_Weigh_in_Motion_Stations.csv bundle exec rake import:weigh_stations
