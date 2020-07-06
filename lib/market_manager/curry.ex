defmodule MarketManager.Curry do
  @moduledoc """
  Contains functions that make currying and partial application easier.
  Based on the blog post: http://blog.patrikstorm.com/function-currying-in-elixir
  """

  def create(fun) do
    {_, arity} = :erlang.fun_info(fun, :arity)
    create(fun, arity, [])
  end

  def create(fun, 0, arguments) do
    apply(fun, Enum.reverse arguments)
  end

  def create(fun, arity, arguments) do
    fn arg -> create(fun, arity - 1, [arg | arguments]) end
  end

end
