module GameEngine
  module Controller
    def self.advance_game(game_data, player_id)
      # This method is responsible for switching phases inside of the GameEngine::Game
      # class when passed the ActiveRecord model of the game and the player_id for the
      # client that's making the request. This code is not very pretty and has a lot of
      # nested conditionals.
      # ===========================================
      # NEEDS TO BE REFACTORED BEFORE FINAL VERSION.
      # ===========================================
      game_state = GameEngine::Cache.fetch_game_state(game_data)
      current_time = Time.now

      if game_state.phase == :setup
        if current_time - game_state.time >= GAME_RULES[:setup_time]
          game_state.phase = :move
          game_state.time = Time.now
          game_state.deal_cards
          GameEngine::Cache.save_game_state(game_state)
          GameEngine::IO.output_player_data(game_state, player_id)
        end
      elsif game_state.phase == :move
        if current_time - game_state.time >= GAME_RULES[:move_time]
          if game_state.target_player(player_id.to_i).selection.empty?
            game_state.target_player(player_id.to_i).selection << nil
            GameEngine::Cache.save_game_state(game_state)
            GameEngine::IO.output_player_data(game_state, player_id)
          end
        end

        if !game_state.player_one.selection.empty? && !game_state.player_two.selection.empty?
          game_state.phase = :resolution
          game_state.time = Time.now
          GameEngine::Cache.save_game_state(game_state)
          GameEngine::IO.output_player_data(game_state, player_id)
        end
      else
        GameEngine::GameRunner.resolve_round(game_state) unless game_state.player_one.selection.empty?
        if current_time - game_state.time >= GAME_RULES[:resolution_time]
          game_state.round += 1
          game_state.phase = :move
          game_state.deal_cards
          GameEngine::Cache.save_game_state(game_state)
        end
      end

      GameEngine::IO.output_player_data(game_state, player_id)
    end
  end
end