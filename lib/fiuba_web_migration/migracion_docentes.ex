defmodule Migracion_docentes do
  import Utils

  # alias FiubaWebMigration.Repo

  # def cargar_docentes() do
  #   query_sql =
  #     "SELECT
  #       menu_links.mlid AS mlid,
  #       menu_links.link_title AS titulo,
  #       REPLACE(menu_links.link_path, 'node/','') AS nid
  #     FROM menu_links
  #     WHERE menu_links.mlid = 906
  #     AND menu_links.router_path= 'node/%';"

  #   {:ok, respuesta} = Repo.query(query_sql)
  #   respuesta.rows
  # end

  def docentes() do
    docentes = cargar_nodo_padre_standard(906) |> Enum.at(0)

    nid = docentes |> Enum.at(2)
    nodo = cargar_nodo(nid) |> Enum.at(0)

    nombre_pagina = nodo |> Enum.at(0)
    texto_pagina = nodo |> Enum.at(1)

    id_pagina_docentes = crear_pagina(nombre_pagina, texto_pagina, nombre_pagina)

    url_docentes = "/docentes"
    crear_navegacion(url_docentes, nombre_pagina, id_pagina_docentes)

    docentes_opts = docentes |> Enum.at(0) |> cargar_hijos()

    Enum.map(
      docentes_opts,
      fn elemento ->
        busqueda_recursiva(elemento, url_docentes, nombre_pagina, nombre_pagina)
      end
    )
  end
end