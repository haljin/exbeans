defmodule ApplicationTest do
  use ExUnit.Case
  @moduledoc false

 test "Supervision test" do
   {:ok, _spid} = Games.Supervisor.start_link()
   {:ok, pid} = Games.Supervisor.start_game(:testGame)
   ^pid = Process.whereis(:testGame)
   {:ok, anotherpid} = Games.Supervisor.start_game(:otherGame)
   ^anotherpid = Process.whereis(:otherGame)

   {:error, {:already_started, ^pid}} = Games.Supervisor.start_game(:testGame)

   Process.exit(pid, :some_error)

   :timer.sleep(10)

   assert is_pid(Process.whereis(:testGame))
   assert Process.whereis(:testGame) != pid
 end

 test "Player sup test" do
     {:ok, _spid} = Games.Supervisor.start_link()
     {:ok, _pid} = Games.Supervisor.start_game(:testGame)
     {:ok, _pspid} = Players.Supervisor.start_link()
     {:ok, _playerPid} = Players.Supervisor.new_player(:testPlayer)

     :ok = Player.join_game(:testPlayer, :testGame)
  end

 test "Main sup" do
    {:ok, _spid} = ExBeansSup.Supervisor.start_link()
    assert is_pid(Process.whereis(Games.Supervisor))
    assert is_pid(Process.whereis(Players.Supervisor))

  end

 test "Application" do
    :ok = Application.start(:exbeans)
    assert is_pid(Process.whereis(Games.Supervisor))
    assert is_pid(Process.whereis(Players.Supervisor))
    Application.stop(:exbeans)
    assert Process.whereis(Games.Supervisor) == nil
  end

 test "Monitors" do
    :ok = Application.start(:exbeans)
    {:ok, pid} = Games.Supervisor.start_game(:testGame)
    {:ok, playerPid} = Players.Supervisor.new_player(:testPlayer)

    :ok = Player.join_game(:testPlayer, :testGame)
    ref = Process.monitor(playerPid)
    Process.exit(pid, :some_error)

    assert_receive {:DOWN, ref, :process, playerPid, :normal}, 500

    refute Process.alive? playerPid
    Application.stop(:exbeans)

  end
end