defmodule Helper.ServiceHelper do
  defmacro __using__(_opts) do
    quote do
      def required_param(param, keys \\ "parameter is empty", message \\ "parameter is empty")
      # def required_param(param, key_name, message \\ "parameter is empty")

      @doc """
      Check values on nil

      ACCCEPT required_param(id: "var")
      ## Examples
        iex > required_param(%{map: nil, map2: nil})

        {:error, %{map: "is_not_nil",map2: "is_no_nil"}}

        iex > required_param(%{map: "!@3", map2: "!@#"})

        :ok
      """
      def required_param(param, keys, message) when is_map(param) and is_list(keys) do
        Enum.map(keys, fn key ->
          if is_nil(param[key]), do: throw({:error, %{key => message}})
        end)

        :ok
      end

      @doc """
         Check value on nil

         ACCCEPT required_param(value, message)
         ## Examples

        iex > required_param(nil, "nil")

        {:error, "nil"}

        iex > required_param(nil, "nil")

        :ok
      """
      def required_param(param, message, _message) do
        if is_nil(param), do: throw({:error, "#{message}"})

        :ok
      end

      @doc """
        Validates a map
         ## Examples

        iex> validate_param(%{"item" => "value"}, %{"item" => %{is_required: true, type: :string}})

        []

        iex> validate_param(
          %{"item" => "value", "count" => 3},
          %{
            "item" => %{is_required: true, type: :integer},
            "count" => %{is_required: false, custom: {&(&1 == 2), "must be 2"}},
            "useless" => %{is_required: true}
            }
          )

        ["useless is required", "item must be of type integer", "count must be 2"]
      """
      def validate_param(params, reqs) do
        Enum.reduce(reqs, [], fn {key, reqs}, acc ->
          acc =
          if Map.get(reqs, :is_required, false) do
            if is_nil(Map.get(params, key)) do
              ["#{key} is required" | acc]
            else
              acc
            end
          else
            acc
          end
          acc =
          if Map.get(reqs, :type, false) do
            with param when not is_nil(param) <- Map.get(params, key) do
              case reqs.type do
                :string -> is_bitstring(param)
                :integer -> is_integer(param)
                :boolean -> is_boolean(param)
                :float -> is_float(param)
                :number -> is_number(param)
                :list -> is_list(param)
                :map -> is_map(param)
              end
              |> if do
                acc
              else
                ["#{key} must be of type #{reqs.type}" | acc]
              end
            else
              _ -> acc
            end
          else
            acc
          end
          acc =
          if Map.get(reqs, :custom, false) do
            with param when not is_nil(param) <- Map.get(params, key) do
              try do
                if elem(reqs.custom, 0).(param) do
                  acc
                else
                  ["#{key} #{elem(reqs.custom, 1)}" | acc]
                end
              rescue
                _ -> acc
              end
            else
              _ -> acc
            end
          else
            acc
          end
        end)
      end

      def validate_param!(params, reqs) do
        validate_param(params, reqs)
        |> case do
          [] -> :ok
          err -> throw {:error, err}
        end
      end

      def reqs(is_required, type, custom), do: %{is_required: is_required, type: type, custom: custom}

      @doc """
      Accepts a function if there are no errors throw returns the execution result
      If there are still errors, return the result of the error

      ## Examples
        iex> func = fn x -> throw(x) end

        iex> return_throw(func("ERROR"))

        "ERROR"

        iex> return_throw(__MODULE__.func(params))

      (throw or result function)
      """
      defmacro return_throw(function) do
        quote do
          try do
            unquote(function)
          catch
            any -> any
          end
        end
      end
    end
  end
end
