# frozen_string_literal: true

require 'rapidjson/json_gem'
require 'honeybadger'
require 'aws-sdk-s3'
require 'date'
require 'minitest/test_task'

Minitest::TestTask.create

require_relative 'logging'
require_relative 'db'
require_relative 'fetchers/towns'
require_relative 'fetchers/teams'
require_relative 'fetchers/players'
require_relative 'fetchers/base_rosters'
require_relative 'fetchers/tournament/details'
require_relative 'fetchers/tournament/results'
require_relative 'fetchers/tournament/rosters'
require_relative 'standalone/season'
require_relative 'backup/postgres'
require_relative 'exporters/continuity'

Honeybadger.configure do |config|
  config.exceptions.rescue_rake = true
end

logger = Loggable.logger

namespace :towns do
  task :fetch_all do
    fetch_all_towns
  end
end

namespace :teams do
  task :fetch_all do
    fetch_all_teams
  end
end

namespace :players do
  task :fetch_all do
    fetch_all_players
  end
end

namespace :base_rosters do
  task :fetch_id_range, [:first_id, :number_of_ids] do |_t, args|
    last_id = if args[:number_of_ids].nil?
                max_team_id + 500
              else
                args[:first_id].to_i + args[:number_of_ids].to_i - 1
              end
    ids = (args[:first_id].to_i..last_id.to_i).to_a
    logger.info "fetching rosters for ids from #{args[:first_id]} to #{last_id}"
    BaseRostersFetcher.new(ids:).run
  end

  task :fetch_for_teams_in_rating_tournaments do
    BaseRostersFetcher.new(ids: teams_that_played_rating_tournaments).run
  end
end

namespace :tournaments do
  task :details_for_all_tournaments do
    TournamentDetailsFetcher.new(category: :all).run
  end

  task :details_for_rating_tournaments do
    TournamentDetailsFetcher.new(category: :maii).run
  end

  task :details_for_recent_tournaments do
    TournamentDetailsFetcher.new(category: :recent).run
  end

  task :details_for_recently_updated_tournaments do
    TournamentDetailsFetcher.new(category: :recently_updated).run
  end

  task :results_for_all do
    TournamentResultsFetcher.new(ids: all_tournaments).run
  end

  task :results_for_rating do
    TournamentResultsFetcher.new(ids: rating_tournaments).run
  end

  task :results_for_recent, [:days] do |_t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentResultsFetcher.new(ids:).run
  end

  task :results_for_single_tournament, [:id] do |_t, args|
    TournamentResultsFetcher.new(ids: [args[:id].to_i]).run
  end

  task :rosters_for_all do
    TournamentRostersFetcher.new(ids: all_tournaments).run
  end

  task :rosters_for_rating do
    TournamentRostersFetcher.new(ids: rating_tournaments).run
  end

  task :rosters_for_recent, [:days] do |_t, args|
    ids = recent_tournaments(days: args[:days].to_i)
    TournamentRostersFetcher.new(ids:).run
  end

  task :rosters_for_single_tournament, [:id] do |_t, args|
    TournamentRostersFetcher.new(ids: [args[:id].to_i]).run
  end
end

namespace :seasons do
  task :fetch_all do
    SeasonsImporter.new.run
  end
end

task :vacuum do
  logger.info 'starting VACUUM FULL'
  vacuum_full
  logger.info 'finished VACUUM FULL'
end

namespace :export do
  task :continuity do
    year_ago = Time.now - (60 * 60 * 24 * 365)
    WrongTeamIDsExporter.new(with_start_date_after: year_ago).run
  end
end

at_exit do
  Honeybadger.stop
end
