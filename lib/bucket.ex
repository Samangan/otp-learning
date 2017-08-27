
defmodule KV.Bucket do
  # NOTE: From h (Agent):
  # Finally note use Agent defines a `child_spec/1` function, allowing the defined
  # module to be put under a supervision tree.
  use Agent, restart: :temporary # https://elixir-lang.org/getting-started/mix-otp/dynamic-supervisor.html
                                 # http://erlang.org/doc/design_principles/sup_princ.html

  # NOTE: `start_link/1` starts the Agent process.
  @doc """
  Starts a new bucket.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, fn bucket -> Map.get(bucket, key) end)
  end

  def put(bucket, key, value) do
    Agent.update(bucket, &(Map.put(&1, key, value)))
  end

  def delete(bucket, key) do
    Process.sleep(1000) # puts client to sleep

    Agent.get_and_update(bucket, fn dict ->
      # NOTE: Everything that is inside the function we
      # passed to the agent happens in the agent process.
      #
      # When a long action is performed on the server, all
      # other requests to that particular server will wait
      # until the action is done, which may cause some
      # clients to timeout.

      Process.sleep(1000) # puts server to sleep

      Map.pop(dict, key)
    end)
  end




end
