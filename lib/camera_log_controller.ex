defmodule EvercamMedia.LogController do
  use EvercamMedia.Web, :controller
  use Calendar
  import Ecto.Query
  alias EvercamMedia.ErrorView
  alias EvercamMedia.LogView

  # A series of plugs makes it clear the transformations on the connection
  # as it moves through processing.  And any the plug finds an error it
  # can halt the chain and return an error
  plug retrieve_camera
  plug check_edit_permission
  plug extract_query_parameters
  plug validate_from_less_than_to

  # Because we ensure all the data is present and correct before we get to the
  # action, we make clear the actual application processing without confusing ourselves
  # with all the validation and paramter extraction.  We also delegate the query processing
  # to the model module.  Could be delegated to a service module, but this case is quite simple
  def show(conn, params) do
    camera = conn.assigns[:camera]
    params = conn.assigns[:query_params]
    activities = CameraActivity.activities(camera, params)
    total_pages = CameraActivity.total_pages(camera, params)
    conn
    |> put_status(200)
    |> render(LogView, "show.json", %{total_pages: total_pages, camera_exid: camera.exid, camera_name: camera.name, results: results})
  end
  
  defp retrieve_camera(conn, _opts) do
    exid = conn.params["id"]
    if camera = Camera.by_exid_with_associations(exid) do
      conn.assign(:camera, camera)
    else   
      conn
      |> put_status(404)
      |> render(ErrorView, "error.json", %{message: "Camera '#{exid}' not found!"})
      |> halt
    end
  end
  
  # Permissions checking should probably be in an Endpoint plug so it is centralized
  defp check_edit_permission(conn, _opts) do
    if conn.assigns[:current_user] && Permission.Camera.can_edit?(conn.assigns[:current_user], conn.assigns[:camera]) do
      conn
    else
      conn 
      |> put_status(401) |> render(ErrorView, "error.json", %{message: "Unauthorized."})
      |> halt
    end
  end

  # Note to do real error reporting you would look at the errors in the changeset
  defp extract_query_params(conn, _opts) do
    case QueryParams.extract(conn) do
      {:ok, conn} -> 
        conn
      {:error, changeset} -> 
        conn 
        |> put_status(422) |> render(ErrorView, "error.json", %{message: "Invalid parameter(s)."})
        |> halt
    end
  end 

  # We can assume we have valid numeric values for from and to so we can just compare.
  # Its good practise to normalize paramters in one place only
  defp validate_from_less_than_to(conn, _opts) do
    if conn.assigns[:query_params]["to"] < conn.assigns[:query_params]["from"] do
      conn 
      |> put_status(400) |> render(ErrorView, "error.json", %{message: "From can't be higher than to."})
      |> halt
    else
      conn
    end
  end
end