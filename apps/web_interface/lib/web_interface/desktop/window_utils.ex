defmodule WebInterface.Desktop.WindowUtils do
  @moduledoc """
  Contains utility functions to determine window attributes.
  """

  @doc """
  Calculates the width and height for the window. Fetches the display
  information using :wx. Because we create a :wx server every time we call this
  function this is a heavy operation and should be used cautiously.

  Both percentages given must be > 0 and <= 1.
  """
  @spec calculate_window_size(float, float) :: {pos_integer, pos_integer}
  def calculate_window_size(width_percentage, height_percentage)
      when is_float(width_percentage) and width_percentage > 0 and width_percentage <= 1 and
             is_float(height_percentage) and height_percentage > 0 and height_percentage <= 1 do
    # Since Desktop has not yet started its wx server, we need to create one
    # to get the screen size first
    _wx_object = :wx.new()

    display = :wxDisplay.new()
    {_x, _y, total_width, total_height} = :wxDisplay.getClientArea(display)

    width_pixels = ceil(width_percentage * total_width)
    height_pixels = ceil(height_percentage * total_height)

    # we destroy the previously created wx server to save resources and avoid
    # a conflict with Desktop library
    :wx.destroy()

    {width_pixels, height_pixels}
  end
end
