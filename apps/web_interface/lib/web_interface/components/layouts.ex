defmodule WebInterface.Layouts do
  @moduledoc false

  use WebInterface, :html

  embed_templates "layouts/*"
end
