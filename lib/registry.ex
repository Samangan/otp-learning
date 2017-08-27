# https://hexdocs.pm/elixir/GenServer.html


# KV.Registry is a process registry that associates a bucket name with a
# particular process. It will monitor each process.

defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry. (Currently only called by KV.Supervisor.init())
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    # NOTE: There are two types of requests you can send to a
    # GenServer: calls and casts.
    #
    # Calls are synchronous and the server must send a response
    # back to such requests.
    GenServer.call(server, {:lookup, name})
  end

  # Note:
  # In a real application we would have probably implemented the
  # callback for :create with a synchronous call instead of
  # an asynchronous cast. We are doing it this way to illustrate
  # how to implement a cast callback.

  @doc """
  Ensures there is a bucket associated with the given `name` in
  `server`
  """
  def create(server, name) do
    # NOTE: Casts are asynchronous and the server
    # won’t send a response back.
    GenServer.cast(server, {:create, name})
  end


  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end


  ## Server Callbacks

  def init(:ok) do
    names = %{} # name -> pid
    refs = %{}  # ref -> name
    {:ok, {names, refs}}
  end

  # NOTE:
  #`:lookup`is the `lookup()` client function defined above.
  # `_from` is the process where we recieved the request from.
  # `names` is the current server state.
  def handle_call({:lookup, name}, _from, {names, _} = state) do
    # Server response format:
    # {:reply, <reply>, new_state}
    # {<what this is>, <the actual response sent to client>, <the new server state>}
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      # NOTE: Recall that calls are synchronous but casts are async
      # and therefore send no replys back to the client. (Thus the `:noreply`)
      # Format: {:noreply, <new state>}
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.BucketSupervisor.start_bucket()
      ref = Process.monitor(pid)

      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # Clean up data tied to dead bucket process:
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

    # If we had more functions for the client to call then we would
    # just add more clauses of `handle_call|cast` with different
    # requests patterned matched, cool.
end
