defmodule EvercamMedia.LogController do
  use EvercamMedia.Web, :controller
  use Calendar
  import Ecto.Query
  alias EvercamMedia.ErrorView
  alias EvercamMedia.LogView

  plug retrieve_camera
  plug check_edit_permission
  plug extract_query_parameters
  plug validate_from_less_than_to

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
  
  defp check_edit_permission(conn, _opts) do
    if conn.assigns[:current_user] && Permission.Camera.can_edit?(conn.assigns[:current_user], conn.assigns[:camera]) do
      conn
    else
      conn 
      |> put_status(401) |> render(ErrorView, "error.json", %{message: "Unauthorized."})
      |> halt
    end
  end

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