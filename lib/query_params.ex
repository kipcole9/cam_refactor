defmodule QueryParams do
  @moduledoc """
  General purpose query parameter extraction, sanitization, normalization
  """
  @default_limit 50
  @types %{
    "from"  =>  :integer,
    "to"    =>  :integer,
    "limit" =>  :integer,
    "page"  =>  :integer,
    "types" =>  :string
  }
  @names Map.keys(@types)
  
  @doc """
  Extract the required parameters from the conn and cast them to the right data type
  
  The cast ensures the correct types, or nil making it easier to do downstream
  transforms.
  """
  def extract(conn) do
    changeset = Ecto.Changeset.cast({%{}, @types}, conn.params, @names)
    if changeset.valid? do
      params = Ecto.Changeset.apply_changes(changeset) |> sanitize_params
      conn = conn.assign(:query_params, params)
      {:ok, conn.assigns[:query_params]}
    else
      {:error, changeset}
    end
  end
  
  @doc """
  Set parameter defaults if none exists, or a normalized value
  as required
  """
  def sanitize_params(params) do
    params
    |> normalize_to
    |> normalize_from
    |> normalize_limit
    |> normalize_page
    |> normalize_types
  end
  
  # Using a standardized params map allows us to add other parameters and
  # keep the transformed parameters in one place in the connection so
  # that if required we can use this module in many different places
  defp normalize_to(%{"to" => to} = params) when is_nil(to), 
    do: %{params | "to" => DateTime.now_utc |> DateTime.to_erl}
  defp normalize_to(%{"to" => to} = params), 
    do: %{params | "to" =>  to |> DateTime.Parse.unix! |> DateTime.to_erl}

  defp normalize_from(%{"from" => from} = params) when is_nil(from), 
    do: %{params | "from" => CameraActivity.min_date() |> Ecto.DateTime.to_erl}
  defp normalize_from(%{"from" => from} = params),
     do: %{params | "from" =>  from |> DateTime.Parse.unix! |> DateTime.to_erl}

  defp normalize_limit(%{"limit" => limit} = params) when is_nil(limit), 
    do: %{params | "limit" => @default_limit}
  defp normalize_limit(%{"limit" => limit} = params), 
    do: %{params | "limit" => if(limit < 1, do: @default_limit, else: limit)}

  defp normalize_page(%{"page" => page} = params) when is_nil(page), 
    do: %{params | "page" => 0}
  defp normalize_page(%{"page" => page} = params), 
    do: %{params | "page" => if(page < 0, do: 0, else: page)}

  defp normalize_types(%{"types" => types} = _params) when is_nil(types), 
    do: nil
  defp normalize_types(%{"types" => types} = params), 
    do: %{params | "types" => types |> String.split(types, ",", trim: true) |> Enum.map(&String.strip/1)}

end