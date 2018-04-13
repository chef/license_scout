defmodule MixLockJson.CLI do
  def main(mix_lock_path \\ "") do
    mix_lock_path
    |> parse_mix_lock
    |> IO.puts
  end

  defp parse_mix_lock(mix_lock_path) do
    {:ok, lockfile} = File.read(mix_lock_path)
    {lock_deps, _} = lockfile |> Code.eval_string

    Poison.encode!(Enum.reduce(lock_deps, [], fn(i, acc) ->
      case i do
        {name, {_, _, version, _hash, _, _child_deps, _}} -> [%{name => version} | acc]
        {name, {:git, _path, hash, _}} -> [%{name => hash} | acc]
        _ -> acc
      end
    end))
  end
end
