defmodule Helper.MnesiaHelper do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @table_name opts[:table_name]
      @table_struct opts[:table_struct]
      @table_type opts[:type] || :disc_copies

      if is_nil(@table_name) do
        throw({:error, __MODULE__, "table_name is not specified in parameters"})
      end

      if is_nil(@table_struct) do
        throw({:error, __MODULE__, "table_struct is not specified in parameters"})
      end

      def create_table do
        try do
          :mnesia.table_info(@table_name, :arity)

          :ok
        catch
          :exit, {:aborted, {:no_exists, _, _}} ->
            :mnesia.stop()
            :mnesia.create_schema([node()])
            :mnesia.start()

            attributes = Map.to_list(%{:attributes => @table_struct, @table_type => [node()]})

            :mnesia.create_table(@table_name, attributes)

            :ok
        end
      end

      def read(id) do
        case :mnesia.dirty_read({@table_name, id}) do
          [] -> nil
          [item] -> create_objest_map(item)
        end
      end

      def write(params) when is_map(params) do
        data =
          Enum.reduce(@table_struct, {@table_name}, fn key, acc ->
            Tuple.append(acc, params[key])
          end)

        data
        |> :mnesia.dirty_write()
        |> case do
          :ok -> create_objest_map(data)
          any -> any
        end
      end

      def select(params \\ %{}) do
        count = Enum.count(@table_struct)

        struct =
          Enum.reduce(0..(count - 1), %{}, fn num, acc ->
            key = Enum.at(@table_struct, num)

            Map.merge(acc, %{key => :"$#{num + 1}"})
          end)

        tuple_struct = List.to_tuple(@table_struct)

        tuple_var =
          Enum.reduce(0..(count - 1), {@table_name}, fn num, acc ->
            key = Enum.at(@table_struct, num)

            Tuple.append(acc, struct[key])
          end)

        params =
          Map.to_list(params)
          |> Enum.reduce([], fn {key, value}, acc ->
            data_key = struct[key]

            if is_tuple(value) do
              {operand, val} = value

              acc ++ [{operand, data_key, val}]
            else
              acc ++ [{:==, data_key, value}]
            end
          end)

        data = [{tuple_var, params, [:"$$"]}]

        {:atomic, items} = :mnesia.transaction(fn -> :mnesia.select(@table_name, data) end)

        Enum.map(items, &create_objest_map/1)
      end

      def match(params \\ %{}) do
        data =
          Enum.reduce(@table_struct, {@table_name}, fn key, acc ->
            value = params[key] || :_

            Tuple.append(acc, value)
          end)

        {:atomic, items} = :mnesia.transaction(fn -> :mnesia.match_object(data) end)

        Enum.map(items, &create_objest_map/1)
      end

      def delete(item) do
        :mnesia.transaction(fn ->
          if(is_struct(item), do: Map.from_struct(item), else: item)
          |> object_to_tuple()
          |> :mnesia.delete_object()
        end)
      end

      defp object_to_tuple(params) do
        Enum.reduce(@table_struct, {@table_name}, fn key, acc ->
          Tuple.append(acc, params[key])
        end)
      end

      defp create_objest_map(data) when is_list(data) do
        data
        |> List.to_tuple()
        |> create_objest_map()
      end

      defp create_objest_map(data) when is_tuple(data) do
        [first | any] = data = Tuple.to_list(data)
        count = Enum.count(@table_struct)

        data = if first == @table_name, do: any, else: data


        Enum.reduce(0..(count - 1), [], fn num, acc ->
          key = Enum.at(@table_struct, num)
          value = Enum.at(data, num)

          [{key, value}] ++ acc
        end)
        |> Map.new()


      end
    end
  end
end
