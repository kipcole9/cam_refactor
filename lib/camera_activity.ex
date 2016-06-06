defmodule CameraActivity do
  use EvercamMedia.Web, :model
  import Ecto.Changeset
  import Ecto.Query
  alias EvercamMedia.Repo

  @required_fields ~w(camera_id)
  @optional_fields ~w(action done_at)

  schema "camera_activities" do
    belongs_to :camera, Camera
    belongs_to :access_token, AccessToken

    field :action, :string
    field :done_at, Ecto.DateTime, default: Ecto.DateTime.utc
    field :extra, EvercamMedia.Types.JSON
    field :camera_exid, :string
    field :name, :string
  end

  def min_date do
    (from c in CameraActivity,
      select: min(c.done_at))
      |> Repo.one
  end

  def changeset(camera_activity, params \\ :invalid) do
    camera_activity
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:camera_id, name: :camera_activities_camera_id_done_at_index)
  end
  
  def activities_query(camera, params) do
    CameraActivity
    |> where(camera_id: ^camera.id)
    |> where([c], c.done_at >= ^params["from"] and c.done_at <= ^params["to"])
    |> with_types_if_specified(types)
  end

  def total_pages(camera, params) do
    from(c in activities_query(camera, params))
    |> select([c], count(c.id))
    |> Repo.one
    |> Kernel./(params["limit"])
    |> Float.floor
  end

  def activities(camera, params) do
    activities_query(camera, params["from"], params["to"])
    |> order_by([c], desc: c.done_at)
    |> limit(^params["limit"])
    |> offset(^(params["page"] * params["limit"]))
  end
  
  defp with_types_if_specified(query, nil) do
    query
  end
  defp with_types_if_specified(query, types) do
    query
    |> where([c], c.action in ^types)
  end
end