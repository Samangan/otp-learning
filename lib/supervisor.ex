
defmodule KV.Supervisor do
  # NOTE: Recall what `use` does
  # https://elixir-lang.org/getting-started/alias-require-and-import.html#use
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      KV.BucketSupervisor, # NOTE: For BucketSupervisor, the name is not passed in via `opts`, but is defined in the module.
      {KV.Registry, name: KV.Registry}
    ]
    # NOTE: `:one_for_all` supervision strategy will kill
    #        and restart all child processes if any one dies
    Supervisor.init(children, strategy: :one_for_all)
  end
end
