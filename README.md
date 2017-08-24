# Exbeans
[![Build Status](https://travis-ci.org/haljin/exbeans.svg?branch=master)](https://travis-ci.org/haljin/exbeans)

## Installation

The library can be installed by adding `exbeans` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exbeans, git: "https://github.com/haljin/exbeans.git"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) using Mix.

## Starting up

Starting new Bohnanza game can be done using:

```elixir
 Games.Supervisor.start_game(<GameName>, <Player1Name>, <Player2Name>)
```
where the names are some identifiers (not neccessarily unique). Identifiers can by any terms, although strings are preferred. The call will return PIDs of the processes started on a keyword list.

## Playing the game

The game is initiated by having players register with the game using `elixir ExBeans.Player.join_game/3`. Once both players are registered the game will be initialized. 

In general outside applications should only interact with the `ExBeans.Player` module to send inputs in the game, although they need to provide callbacks to both `ExBeans.Player` and `ExBeans.BeanGame` processes in order to receive notifications about the state of the game.

Please see the generated documentation for more details about the API.
