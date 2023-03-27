defmodule RelaSetupHelper do
  import Ecto.Query
  @sql Ecto.Adapters.SQL
  @chng Ecto.Changeset
  @repo ApiCore.Repo

  def run do
    conns = ApiCore.Rela.get_conns()
    keys = green_key()

    alter_or_create_r_tables(conns)
    update_from_previous_version(conns, keys)
  end

  def alter_or_create_r_tables(conns) do
    Enum.map(conns, fn {{actor, _}, _} -> actor.__struct__.__meta__.source end)
    |> Enum.uniq()
    |> Enum.each(
      &if(not @sql.table_exists?(@repo, "r_#{&1}"),
        do:
          @sql.query(
            @repo,
            "CREATE TABLE r_#{&1} (id serial PRIMARY KEY, actor_id INT NOT NULL, contractor_id INT NOT NULL, contractor VARCHAR(50) NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT NOW(), is_deleted BOOLEAN NOT NULL DEFAULT false, FOREIGN KEY (actor_id) REFERENCES #{&1} (id))"
          ),
        else:
          try do
            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} RENAME COLUMN start_date TO created_at"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} RENAME COLUMN status TO is_deleted"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} ALTER COLUMN is_deleted TYPE BOOLEAN USING false"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} ADD CONSTRAINT r_#{&1}_pkey FOREIGN KEY (actor_id) REFERENCES #{&1} (id)"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} DROP COLUMN type_id, DROP COLUMN end_date"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} ALTER COLUMN is_deleted SET default false"
            )

            @sql.query(
              @repo,
              "ALTER TABLE r_#{&1} ALTER COLUMN created_at SET default now()"
            )
          rescue
            error -> IO.inspect(error)
          catch
            error -> IO.inspect(error)
          end
      )
    )
  end

  def update_from_previous_version(conns, key) do
    Enum.map(conns, fn {{actor, _}, _} -> actor.__struct__.__meta__.source end)
    |> Enum.uniq()
    |> Enum.each(fn table ->
      @repo.transaction(fn ->
        Enum.each(
          @repo.all(from(r in {"r_#{table}", Rela})),
          fn rela ->
            @repo.update(@chng.change(rela, contractor: Map.get(key, rela.contractor, rela.contractor)))
          end
        )
      end)
    end)
  end

  def green_key() do
    %{
      "organization" => "organizations",
      "person" => "persons",
      "personnel" => "personnels",
      "vendor" => "vendors",
      "cashbox" => "cashboxes",
      "client" => "clients",
      "partner" => "partners",
      "provider" => "providers",
      "store" => "stores",
      "user" => "users",
      "sim_card" => "sim_cards",
      "email_box" => "email_boxes",
      "location" => "locations"
    }
  end
end
