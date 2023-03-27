defmodule Helper.CryptoHelper do
  def hash(str), do: Base.encode16(:crypto.hash(:sha256, str))
  def hash64(str, type \\ :sha512), do: Base.encode64(:crypto.hash(type, str))
end
