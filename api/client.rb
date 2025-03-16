# frozen_string_literal: true

require_relative '../logging'

class APIClient
  include Loggable
  include HTTParty
  base_uri 'https://api.rating.chgk.info'
  ITEMS_PER_PAGE = 100
  TOURNAMENTS_PER_PAGE = 50

  def initialize
    @headers = { accept: 'application/json' }
  end

  def all_tournaments(page:)
    paged_fetch('/tournaments?', page, items_per_page: TOURNAMENTS_PER_PAGE)
  end

  def maii_tournaments(page:)
    paged_fetch('/tournaments?properties.maiiRating=true', page, items_per_page: TOURNAMENTS_PER_PAGE)
  end

  def tournaments_started_after(date:, page:)
    paged_fetch("/tournaments?dateStart%5Bafter%5D=#{date}", page, items_per_page: TOURNAMENTS_PER_PAGE)
  end

  def tournaments_updated_after(date:, page:)
    paged_fetch("/tournaments?lastEditDate%5Bafter%5D=#{date}", page, items_per_page: TOURNAMENTS_PER_PAGE)
  end

  def tournament_results(tournament_id:)
    params = 'results?includeTeamMembers=0&includeMasksAndControversials=1&includeTeamFlags=0&includeRatingB=0'
    fetch("/tournaments/#{tournament_id}/#{params}")
  end

  def tournament_rosters(tournament_id:)
    params = 'results?includeTeamMembers=1&includeMasksAndControversials=0&includeTeamFlags=1&includeRatingB=0'
    fetch("/tournaments/#{tournament_id}/#{params}")
  end

  def team_rosters(team_id:)
    fetch("/teams/#{team_id}/seasons?page=1&itemsPerPage=500")
  end

  def towns(page:)
    paged_fetch('/towns?', page)
  end

  def teams(page:)
    fetch("/teams?page=#{page}&itemsPerPage=500")
  end

  def players(page:)
    fetch("/players?page=#{page}&itemsPerPage=500")
  end

  def seasons
    fetch('/seasons')
  end

  private

  def paged_fetch(query, page, items_per_page: ITEMS_PER_PAGE)
    fetch("#{query}&itemsPerPage=#{items_per_page}&page=#{page}")
  end

  def fetch(query)
    attempts = 0
    begin
      attempts += 1
      response = self.class.get(query.to_s, headers: @headers)
      JSON.parse(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, JSON::ParserError
      logger.warn "connection refused at #{query}, retrying in 3 seconds"
      sleep(3)
      retry if attempts < 3
      logger.error "connection refused at #{query}, giving up"
      raise
    end
  end
end
