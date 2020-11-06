# Pigeon

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pigeon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pigeon, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pigeon](https://hexdocs.pm/pigeon).

## Cómo correr V1

En una consola
```bash
iex --sname server@localhost -S mix
```
```bash
{:ok, pid1} = Pigeon.UserRegistry.start_link(User1)
{:ok, pid2} = Pigeon.UserRegistry.start_link(User2)
```

En otra consola
```bash
iex --sname nodo1@localhost -S mix
```
```bash
pid = Pigeon.User.login(User1)
Pigeon.User.create_group_room(pid, IASC)
#Pigeon.User.create_chat(pid, IASC) -- sala individual
#Pigeon.User.create_secret_room(pid, IASC) -- sala individual secreta 
```

En otra consola
```bash
iex --sname nodo2@localhost -S mix
```
```bash
pid = Pigeon.User.login(User2)
Pigeon.User.join_room(pid, IASC)
```

Listo ya está todo conectado, ahora para mandar un mensaje:

Consola 1 (nodo1)
```bash
Pigeon.User.send_message_to_room(pid, IASC, "Hola mundo!")
```

Para ver los mensajes, en el nodo server:

```bash
Pigeon.Rooms.Room.list_messages(IASC)
```