defmodule Helper.RedixHelper do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @table_name opts[:table_name]
      def create_table() do
        :ok
      end

      def write(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["SET", "#{@table_name}:#{id}", :erlang.term_to_binary(params)])
          params
        else
          {:error, "no id"}
        end
      end

      def write(params, secondary_id) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["SET", "#{@table_name}:#{id}:#{secondary_id}", :erlang.term_to_binary(params)])
          params
        else
          {:error, "no id"}
        end
      end

      def time_limit(params, time) when is_map(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["EXPIRE", "#{@table_name}:#{id}", time])
        else
          {:error, "no id"}
        end
      end

      def time_limit(id, time) do
        Redix.command(:redix, ["EXPIRE", "#{@table_name}:#{id}", time])
      end

      def time_limit(params, secondary_id, time) when is_map(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["EXPIRE", "#{@table_name}:#{id}:#{secondary_id}", time])
        else
          {:error, "no id"}
        end
      end

      def time_limit(id, secondary_id, time) do
        Redix.command(:redix, ["EXPIRE", "#{@table_name}:#{id}:#{secondary_id}", time])
      end

      def read(id) do
        Redix.command(:redix, ["GET", "#{@table_name}:#{id}"])
        |> case do
          {:ok, nil} -> nil
          {:ok, data} -> :erlang.binary_to_term(data)
        end
      end

      def read(id, secondary_id) do
        Redix.command(:redix, ["GET", "#{@table_name}:#{id}:#{secondary_id}"])
        |> case do
          {:ok, nil} -> nil
          {:ok, data} -> :erlang.binary_to_term(data)
        end
      end

      def delete(params) when is_map(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["DEL", "#{@table_name}:#{id}"])
          |> case do
            {:ok, _} -> {:ok, "deleted"}
            any -> any
          end
        else
          {:error, "no id"}
        end
      end

      def delete(id) do
        Redix.command(:redix, ["DEL", "#{@table_name}:#{id}"])
        |> case do
          {:ok, _} -> {:ok, "deleted"}
          any -> any
        end
      end

      def delete(params, secondary_id) when is_map(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["DEL", "#{@table_name}:#{id}:#{secondary_id}"])
          |> case do
            {:ok, _} -> {:ok, "deleted"}
            any -> any
          end
        else
          {:error, "no id"}
        end
      end

      def delete(id, secondary_id) do
        Redix.command(:redix, ["DEL", "#{@table_name}:#{id}:#{secondary_id}"])
        |> case do
          {:ok, _} -> {:ok, "deleted"}
          any -> any
        end
      end

      def set_get() do
        [item | set] =
        Redix.command(:redix, ["GET", "#{@table_name}:set"])
        |> case do
          {:ok, nil} -> [nil]
          {:ok, data} -> :erlang.binary_to_term(data)
        end
        Redix.command(:redix, ["SET", "#{@table_name}:set", :erlang.term_to_binary(set)])
        item
      end

      def set_add(item) do
        set =
        Redix.command(:redix, ["GET", "#{@table_name}:set"])
        |> case do
          {:ok, nil} -> []
          {:ok, data} -> :erlang.binary_to_term(data)
        end
        Redix.command(:redix, ["SET", "#{@table_name}:set", :erlang.term_to_binary(set ++ [item])])
        :ok
      end
    end
  end
end
