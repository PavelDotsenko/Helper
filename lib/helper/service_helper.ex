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
              validate_type(param, reqs.type)
              |> if do
                acc
              else
                [if(is_tuple(reqs.type), do: "each element of #{key} must be of type - #{Regex.replace(~r/\ /, Regex.replace(~r/[^\ \w]+/, inspect(elem(reqs.type, 1)), ""), " of ")}", else: "#{key} must be of type #{reqs.type}") | acc]
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

      defp validate_type(param, type) do
        case type do
          type when type in [:string, :bitstring] -> is_bitstring(param)
          :integer -> is_integer(param)
          :boolean -> is_boolean(param)
          :float -> is_float(param)
          :number -> is_number(param)
          type when type in [:list, :array, :keylist, :charset] -> is_list(param)
          type when type in [:map, :object] -> is_map(param)
          {type, subtype} when type in [:list, :array] -> if(validate_type(param, :list), do: Enum.all?(Enum.map(param, &(validate_type(&1, subtype)))), else: false)
        end
      end

      def reqs(is_required), do: %{is_required: is_required}

      def reqs(is_required, type), do: %{is_required: is_required, type: type}

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
