defmodule Utils do
  alias FiubaWebMigration.Repo
  import Ecto.Query
  import JSON
  import String


  def cargar_imagen(url_imagen) do

    {:ok, result} = HTTPoison.get(url_imagen)

    imagen = result.body
    headers = [{"Content-Type", "multipart/form-data"}]
    options = [ssl: [{:versions, [:'tlsv1.2']}], recv_timeout: 20000]

    {:ok, response_imagen} =
      HTTPoison.request(
      :post,
      "https://testing.cms.fiuba.lambdaclass.com/upload",
      {:multipart,
       [{"file", imagen, {"form-data", [name: "files", filename: "img.jpg"]}, [{"Content-Type", "image/jpeg"}]},{"type", "image/jpeg"}]},
      headers,
      options
    )

    response_body = response_imagen.body
    {:ok, response_body_map} = JSON.decode(response_body)
    {:ok, id_imagen} = Map.fetch( (response_body_map|> Enum.at(0)) , "id")

    id_imagen

  end



  def urls_imgs_embebidas(nid) do

    query_sql = "SELECT
        REPLACE (file_managed.uri,'public://','www.fi.uba.ar/sites/default/files/') AS URL_IMG
      FROM node
      INNER JOIN field_data_field_galeria_embebida ON node.nid = field_data_field_galeria_embebida.entity_id
      LEFT JOIN file_usage ON field_data_field_galeria_embebida.field_galeria_embebida_value = file_usage.id AND file_usage.type = 'field_collection_item'
      LEFT JOIN file_managed ON file_managed.fid = file_usage.fid
      WHERE node.type = 'article' AND node.nid = " <> to_string(nid) <> ";"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows

  end


  def cargar_noticias() do

    query_sql =
      "SELECT
        node.nid as NODO,
        node.title as TITULO,
        field_data_field_date.field_date_value AS FECHA,
        field_data_body.body_value as TEXTO
      FROM node
      INNER JOIN field_data_body ON  node.nid = field_data_body.entity_id
      LEFT JOIN field_data_field_date ON node.nid = field_data_field_date.entity_id
      WHERE node.type = 'article';"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end


  def cargar_maestrias do
    query_sql = "SELECT
        menu_links.link_title AS titulo,
        menu_links.mlid AS mlid
      FROM menu_links
      WHERE menu_links.plid = '1157'
      ORDER BY menu_links.link_title DESC"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_anuales_bianuales do
    query_sql = "SELECT
        menu_links.link_title AS titulo,
        menu_links.mlid AS mlid
      FROM menu_links
      WHERE menu_links.plid = 1159
      ORDER BY menu_links.link_title DESC"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_investigaciones() do
    query_sql = "SELECT
        menu_links.link_title AS titulo,
        menu_links.mlid AS mlid
      FROM menu_links
      WHERE menu_links.plid = 1161 AND menu_links.router_path = 'node/%';"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_investigaciones_hijos(plid) do
    query_sql =
      "SELECT
        menu_links.link_title AS titulo,
        menu_links.mlid AS mlid
      FROM menu_links
      WHERE menu_links.plid = " <>
        to_string(plid) <>
        " AND menu_links.has_children = 0
        AND menu_links.router_path = 'node/%';"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_nodos_asociados_maestrias(mlid) do
    query_sql =
      "SELECT
        menu_links.link_title AS titulo_nodo_asociado,
        REPLACE(menu_links.link_path, 'node/','') AS nid
      FROM menu_links
      WHERE (menu_links.plid = " <>
        to_string(mlid) <> " OR menu_links.mlid = " <> to_string(mlid) <> ");"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_nodos_asociados(mlid) do
    query_sql =
      "SELECT
        menu_links.link_title AS titulo_nodo_asociado,
        REPLACE(menu_links.link_path, 'node/','') AS nid
      FROM menu_links
      WHERE menu_links.link_title != 'Video' AND
            menu_links.link_title != 'Plan de estudios' AND
            menu_links.link_title != 'Autoridades' AND
            (menu_links.plid = " <>
        to_string(mlid) <> " OR menu_links.mlid = " <> to_string(mlid) <> ");"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_texto_asociado(nid) do
    query_sql = "SELECT
        node.title AS titulo_nodo,
        field_data_body.body_value AS texto_asociado
      FROM node
      INNER JOIN field_data_body ON field_data_body.entity_id = node.nid
      WHERE node.nid = " <> to_string(nid) <> ";"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  # def ejemplo_completo_carreras_grado do

  #   carreras = cargar_carreras_grado()

  #   Enum.map(
  #     carreras,
  #     fn carrera ->
  #       nodos_asociados = cargar_nodos_asociados(Enum.at(carrera, 1))
  #       nombre_carrera = Enum.at(carrera, 0)

  #       componentes_pagina =
  #         Enum.map(
  #           nodos_asociados,
  #           fn nodo ->
  #             texto_asociado = Enum.at(cargar_texto_asociado(Enum.at(nodo, 1)), 0)

  #             %{
  #               "__component" => "paginas.texto-con-formato",
  #               "texto" => HtmlSanitizeEx.strip_tags(Enum.at(texto_asociado, 1)),
  #               "encabezado" =>
  #                 if Enum.at(texto_asociado, 0) == nombre_carrera do
  #                   "Propuesta Académica"
  #                 else
  #                   Enum.at(texto_asociado, 0)
  #                 end
  #             }
  #           end
  #         )

  #       # POR CADA CARRERA CREO UNA PAGINA
  #       pagina = %{
  #         "componentes" => componentes_pagina,
  #         "nombre" => nombre_carrera
  #       }

  #       response_pagina =
  #         HTTPoison.post!(
  #           "https://testing.cms.fiuba.lambdaclass.com/paginas",
  #           JSON.encode!(pagina),
  #           [{"Content-type", "application/json"}]
  #         )

  #       response_body = response_pagina.body
  #       {:ok, response_body_map} = JSON.decode(response_body)
  #       {:ok, id} = Map.fetch(response_body_map, "id")

  #       # POR CADA PAGINA CREO UN VINCULO

  #       vinculo = %{
  #         "vinculo" => [
  #           %{
  #             "__component" => "navegacion.pagina",
  #             "pagina" => id
  #           }
  #         ],
  #         "seo_url" =>
  #           "/ensenanza/grado/carreras/" <>
  #             (nombre_carrera
  #              |> String.downcase()
  #              |> String.normalize(:nfd)
  #              |> String.replace(~r/[^A-z\s]/u, "")
  #              |> String.replace(~r/\s/, "-")),
  #         "nombre" => nombre_carrera
  #       }

  #       response_navegacion =
  #         HTTPoison.post!(
  #           "https://testing.cms.fiuba.lambdaclass.com/navegacion",
  #           JSON.encode!(vinculo),
  #           [{"Content-type", "application/json"}]
  #         )

  #       response_body_navegacion = response_navegacion.body
  #       {:ok, response_body_navegacion_map} = JSON.decode(response_body_navegacion)
  #       {:ok, id_navegacion} = Map.fetch(response_body_navegacion_map, "id")

  #       pagina_carrera_response =
  #         HTTPoison.get!("https://testing.cms.fiuba.lambdaclass.com/paginas?nombre=Carreras")

  #       pagina_carrera_response_body = pagina_carrera_response.body
  #       {:ok, response_body_carreras_map} = JSON.decode(pagina_carrera_response_body)
  #       {:ok, id_pagina_carrera} = Map.fetch(Enum.at(response_body_carreras_map, 0), "id")

  #       {:ok, componentes_actuales} =
  #         Map.fetch(Enum.at(response_body_carreras_map, 0), "componentes")

  #       {:ok, links_actuales} = Map.fetch(Enum.at(componentes_actuales, 0), "links")

  #       link = %{
  #         "updid" => id_pagina_carrera,
  #         "componentes" => [
  #           %{
  #             "__component" => "paginas.navegacion-listado",
  #             "links" => links_actuales ++ [%{"navegacion" => id_navegacion}]
  #           }
  #         ]
  #       }

  #       # {"nombre":"Carreras","created_at":"2021-04-13T19:45:16.763Z","componentes":[{"__component":"paginas.navegacion-listado","id":3,"encabezado":null,"links":[{"id":4,"navegacion":40},{"navegacion":68}]}],"created_by":1,"menu_lateral":null,"updated_at":"2021-06-02T03:08:45.832Z","id":24,"updated_by":4,"portada":46}

  #       HTTPoison.put!(
  #         "https://testing.cms.fiuba.lambdaclass.com/paginas/" <> to_string(id_pagina_carrera),
  #         JSON.encode!(link),
  #         [{"Content-type", "application/json"}]
  #       )
  #     end
  #   )
  # end

  def crear_pagina(nombre_pagina \\ "", texto_pagina \\ "", jeraquia_pagina \\ "") do
    pagina = %{
      "nombre" => nombre_pagina,
      "jerarquia" => jeraquia_pagina,
      "componentes" => [
        %{
          "__component" => "paginas.texto-con-formato",
          "texto" => HtmlSanitizeEx.strip_tags(texto_pagina)
        }
      ]
    }

    response_pagina =
      HTTPoison.post!(
        "https://testing.cms.fiuba.lambdaclass.com/paginas",
        JSON.encode!(pagina),
        [{"Content-type", "application/json"}]
      )

    response_body = response_pagina.body
    {:ok, response_body_map} = JSON.decode(response_body)
    {:ok, id_pagina} = Map.fetch(response_body_map, "id")

    id_pagina
  end

  def url_format(string) do
    string
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-Z^a-z^0-9\s]/u, "")
    |> String.replace(~r/\s/, "-")
  end

  @doc """
  Recibe la url generica, el nombre de la navegacion y el id de la pagina a vincular.
  Ejemplo url: /ensenanza/grado/carreras/, nombre_navegacion: "Ingeniería Informática", id_pagina: 27
  """
  def crear_navegacion(url_navegacion, nombre_navegacion, id_pagina) do
    vinculo = %{
      "vinculo" => [
        %{
          "__component" => "navegacion.pagina",
          "pagina" => id_pagina
        }
      ],
      "seo_url" => url_navegacion,
      "nombre" => nombre_navegacion
    }

    response_navegacion =
      HTTPoison.post!(
        "https://testing.cms.fiuba.lambdaclass.com/navegacion",
        JSON.encode!(vinculo),
        [{"Content-type", "application/json"}]
      )
  end

  def cargar_hijos(plid) do
    query_sql = "SELECT
    menu_links.mlid AS mlid,
    menu_links.link_title AS titulo,
    REPLACE(menu_links.link_path, 'node/','') AS nid,
    menu_links.has_children AS tiene_hijos
    FROM menu_links
    WHERE menu_links.plid = " <> to_string(plid) <> " AND menu_links.router_path= 'node/%';"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def cargar_nodo(nid) do
    query_sql = "SELECT
  node.title AS titulo_nodo,
      field_data_body.body_value AS texto_asociado
        FROM node
        LEFT JOIN field_data_body ON field_data_body.entity_id = node.nid
    WHERE node.nid = " <> to_string(nid) <> ";"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows
  end

  def busqueda_recursiva(elemento, url_nav_padre, nombre_nav_padre, jerarquia_padre) do
    nid = elemento |> Enum.at(2)
    nodo = cargar_nodo(nid) |> Enum.at(0)

    titulo = nodo |> Enum.at(0)
    texto = nodo |> Enum.at(1)

    jerarquia_padre = jerarquia_padre <> "/" <> titulo
    id_pagina = crear_pagina(titulo, texto, jerarquia_padre)

    nombre_nav = nombre_nav_padre <> " - " <> titulo
    url_nav = url_nav_padre <> "/" <> (titulo |> url_format())

    resultado = crear_navegacion(url_nav, nombre_nav, id_pagina)

    # 1 = Tiene hijos, 0 = No tiene hijos
    has_children = elemento |> Enum.at(3)

    if has_children == 1 do
      hijos = elemento |> Enum.at(0) |> cargar_hijos()

      Enum.map(
        hijos,
        fn hijo ->
          busqueda_recursiva(hijo, url_nav, nombre_nav, jerarquia_padre)
        end
      )
    end

    resultado
  end
end
