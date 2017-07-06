defmodule ApplicationTest do
  use ExUnit.Case
  @moduledoc false

 test "Supervision test" do
   {:ok, pid} = Games.Supervisor.start_game(:testGame)
   ^pid = Process.whereis(:testGame)
   {:ok, anotherpid} = Games.Supervisor.start_game(:otherGame)
   ^anotherpid = Process.whereis(:otherGame)

   {:error, {:already_started, ^pid}} = Games.Supervisor.start_game(:testGame)

   Process.exit(pid, :some_error)

   :timer.sleep(10)

   assert is_pid(Process.whereis(:testGame))
   assert Process.whereis(:testGame) != pid
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