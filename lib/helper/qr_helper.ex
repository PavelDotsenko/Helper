defmodule Helper.QrHelper do
  def get_qr(image_path) do
    {str, _} =
      System.cmd("python3", ["./lib/t_c/system/qr_read.py", "--input", image_path],
        stderr_to_stdout: true
      )

    case Regex.run(~r/http(?<data>[^\s]+)/, str) do
      nil ->
        {:error, :qr_not_found}

      [link | _] ->
        {:ok, String.replace(link, "\"]", "")}
    end
  end
end
