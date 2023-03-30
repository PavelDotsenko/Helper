defmodule Helper.RestHelper do
  @strftime_format "20%y.%m.%dT%I:%M:%S"

  def prepare({:error, val}), do: prepare(val)

  def prepare(%Date{} = value), do: Date.to_iso8601(value)

  def prepare(%Time{} = value), do: Time.to_iso8601(value)

  def prepare(%DateTime{} = value), do: Calendar.strftime(value, @strftime_format)

  def prepare(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> Calendar.strftime(@strftime_format)
  end

  def prepare(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def prepare(%Ecto.Association.NotLoaded{}), do: nil

  def prepare(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
    |> prepare()
  end

  def prepare(map) when is_map(map) do
    Enum.map(map, fn {key, value} ->
      value = if key == :password or key == :repassword, do: "[SECRET]", else: value

      {key, prepare(value)}
    end)
    |> Map.new()
    |> Map.delete("delete_thiss")
  end

  def prepare(list) when is_list(list), do: Enum.map(list, fn value -> prepare(value) end)

  def prepare(tuple) when is_tuple(tuple), do: Tuple.to_list(tuple) |> prepare()

  def prepare(value) when is_pid(value), do: value

  def prepare(value), do: value
end
