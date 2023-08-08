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
          with {:ok, data} <- Jason.encode(params) do
            Redix.command(:redix, ["SET", "#{id}_#{@table_name}", data])
            |> case do
              {:ok, _} -> params
            end
          end
        else
          {:error, "no id"}
        end
      end

      def read(id) do
        Redix.command(:redix, ["GET", "#{id}_#{@table_name}"])
        |> case do
          {:ok, nil} -> nil
          {:ok, data} -> Jason.decode(data, keys: :atoms)
          |> case do
            {:ok, data} -> data
            {:error, _} -> nil
          end
        end
      end

      def delete(params) when is_map(params) do
        id = Map.get(params, :id, params["id"])
        if id do
          Redix.command(:redix, ["DEL", "#{id}_#{@table_name}"])
          |> case do
            {:ok, _} -> {:ok, "deleted"}
            any -> any
          end
        else
          {:error, "no id"}
        end
      end
    end
  end
end
