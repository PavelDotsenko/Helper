defmodule Helper.ChangesetHelper do
  import Ecto.Changeset, only: [update_change: 3, validate_format: 4]

  def validate_date_time(
        %Ecto.Changeset{changes: changes} = changeset,
        field,
        operator,
        value,
        opts \\ %{}
      )
      when is_atom(field) and is_atom(operator) do
    if is_nil(changes[field]) or is_nil(value) do
      changeset
    else
      if operator_handler(changes[field], value, operator) do
        changeset
      else
        message = opts[:message] || "not_valid_datetime"
        error = [{field, {message, [validation: :validate_date_time]}}]

        changeset
        |> insert_errors(field, error)
      end
    end
  end

  def enum_type_check(%Ecto.Changeset{changes: changes} = changeset, field, type, opts \\ %{})
      when is_atom(field) do
    if is_nil(changes[field]) do
      changeset
    else
      if type.valid_value?(changes[field]) do
        changeset
      else
        message = opts[:message] || "not_valid_type"
        error = [{field, {message, [validation: :enum_type_check]}}]

        changeset
        |> insert_errors(field, error)
      end
    end
  end

  def email_check(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> normalize_string(field)
    |> update_change(field, &downcase_handler/1)
    |> validate_format(field, ~r/^(?<user>[^\s]+)@(?<domain>[^\s]+\.[^\s]+)$/,
      message: "wrong_format"
    )
  end

  def password_check(
        %Ecto.Changeset{changes: changes} = changeset,
        field,
        check_field,
        opts \\ %{}
      )
      when is_atom(field) and is_atom(check_field) do
    cond do
      is_nil(changes[field]) ->
        changeset

      changes[field] == changes[check_field] ->
        changeset

      true ->
        message = opts[:message] || "do_not_match"

        error = [{field, {message, [validation: :password_check]}}]

        changeset
        |> insert_errors(field, error)
    end
  end

  @spec normalize_string(Ecto.Changeset.t(), atom | list | nil) :: Ecto.Changeset.t()
  def normalize_string(changeset, fiels)

  def normalize_string(%Ecto.Changeset{} = changeset, nil), do: changeset

  def normalize_string(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    changeset
    |> update_change(field, &trim_handler/1)
  end

  def normalize_string(%Ecto.Changeset{} = changeset, fiels)
      when is_list(fiels) do
    Enum.reduce(fiels, changeset, fn field, acc ->
      acc
      |> normalize_string(field)
    end)
  end

  @spec security_check(Ecto.Changeset.t(), atom | list | nil, any) :: Ecto.Changeset.t()
  def security_check(changeset, fields, opts \\ %{})

  def security_check(%Ecto.Changeset{} = changeset, nil, _opts), do: changeset

  def security_check(%Ecto.Changeset{changes: changes} = changeset, field, opts)
      when is_atom(field) do
    cond do
      changes[field] == nil ->
        changeset

      Regex.match?(~r/[<>]/, changes[field]) ->
        message = opts[:message] || "has_invalid_characters"

        error = [{field, {message, [validation: :security_check]}}]

        changeset
        |> insert_errors(field, error)

      true ->
        changeset
    end
  end

  def security_check(%Ecto.Changeset{} = changeset, fiels, opts)
      when is_list(fiels) do
    Enum.reduce(fiels, changeset, fn field, acc ->
      acc
      |> security_check(field, opts)
    end)
  end

  defp operator_handler(field, value, :==) when not is_nil(value),
    do: NaiveDateTime.diff(field, value) == 0

  defp operator_handler(field, value, :>) when not is_nil(value),
    do: NaiveDateTime.diff(field, value) > 0

  defp operator_handler(field, value, :<) when not is_nil(value),
    do: NaiveDateTime.diff(field, value) < 0

  defp operator_handler(field, value, :>=) when not is_nil(value),
    do: NaiveDateTime.diff(field, value) >= 0

  defp operator_handler(field, value, :<=) when not is_nil(value),
    do: NaiveDateTime.diff(field, value) <= 0

  defp operator_handler(_field, _value, _), do: true

  defp trim_handler(nil), do: nil
  defp trim_handler(str) when is_binary(str), do: String.trim(str)

  defp downcase_handler(nil), do: nil
  defp downcase_handler(str) when is_binary(str), do: String.downcase(str)

  defp insert_errors(
         %Ecto.Changeset{changes: changes, required: required, errors: errors} = changeset,
         field,
         new_errors
       ) do
    %{
      changeset
      | changes: changes,
        required: [field] ++ required,
        errors: Enum.uniq(new_errors ++ errors),
        valid?: false
    }
  end
end
