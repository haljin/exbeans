defmodule ApplicationTest do
  use ExUnit.Case
  alias ExBeans.Games
  @moduledoc false

 test "Supervision test" do
   {:ok, pid} = Games.Supervisor.start_game(:testGame, :testPlayer, :testPlayer2)
   {:ok, _anotherpid} = Games.Supervisor.start_game(:otherGame, :player1, :player2)

   Process.exit(pid, :kill)
   :timer.sleep(10)

   refute Process.alive?(pid)
   cleanup()
 end

# test "Player sup test" do
#   {:ok, _pid} = Games.Supervisor.start_game(:testGame)
#   {:ok, _playerPid} = Players.Supervisor.new_player(:testPlayer)
#
#   :ok = Player.join_game(:testPlayer, :testGame)
#   cleanup()
#  end
#
#
# test "Monitors" do
#   {:ok, pid} = Games.Supervisor.start_game(:testGame)
#   {:ok, playerPid} = Players.Supervisor.new_player(:testPlayer)
#
#   :ok = Player.join_game(:testPlayer, :testGame)
#   ref = Process.monitor(playerPid)
#   Process.exit(pid, :some_error)
#
#   assert_receive {:DOWN, ref, :process, playerPid, :normal}, 500
#
#   refute Process.alive? playerPid
#   cleanup()
#  end

  defp cleanup() do
    Application.stop(:exbeans)
    Application.start(:exbeans)
  end
end