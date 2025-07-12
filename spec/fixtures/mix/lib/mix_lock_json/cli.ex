require Jason
defmodule MixLockJson.CLI do
  def main(args) do
    # Process the mix.lock file path
    _mix_lock_path = Enum.at(args, 0)

    # Simulate JSON output
    json_output = %{
      dependencies: [
        %{name: "earmark", version: "1.2.5", license: "Apache-2.0"},
        %{name: "ex_doc", version: "0.18.3", license: nil}
      ]
    }

    # Output the JSON using Jason
    IO.puts(Jason.encode!(json_output))
  end
end