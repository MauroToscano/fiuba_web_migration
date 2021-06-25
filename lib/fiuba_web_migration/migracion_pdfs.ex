defmodule Migracion_pdfs do

  alias FiubaWebMigration.Repo
  import Ecto.Query
  import JSON
  import String
  import HTTPoison.Retry
  import Utils


  def cargar_titulos_pdfs do

    query_sql =
      "SELECT
        file_managed.filename AS titulo_pdf
      FROM file_managed
      WHERE
        file_managed.filemime = 'application/pdf' AND
        file_managed.filesize != 0 AND
        file_managed.filename = REPLACE(file_managed.uri,'public://','')
      ORDER BY file_managed.filename;"

    {:ok, respuesta} = Repo.query(query_sql)
    respuesta.rows

  end


  def url_pdf_parser(url_pdf) do

      url_pdf
      |> String.replace(" ", "%20")
      |> String.replace("°", "%C2%BA")
      |> String.replace("ñ", "%C3%B1")

      |> String.replace("á", "%C3%A1")
      |> String.replace("Á", "%C3%81")

      |> String.replace("é", "%C3%A9")
      # |> String.replace("É", )

      |> String.replace("í", "%C3%AD")
      |> String.replace("Í", "%C3%8D")

      |> String.replace("ó", "%C3%B3")
      |> String.replace("Ó", "%C3%93")

      # |> String.replace("ú", )
      # |> String.replace("Ú", )

  end


  def cargar_pdf(titulo_pdf) do

    url_pdf = "http://www.fi.uba.ar/sites/default/files/" <> (titulo_pdf |> url_pdf_parser())

    {:ok, result} =
      HTTPoison.get(url_pdf)
      |> HTTPoison.Retry.autoretry(
        max_attempts: 10,
        wait: 20000,
        include_404s: false,
        retry_unknown_errors: false
      )

    pdf = result.body
    headers = [{"Content-Type", "multipart/form-data"}]
    options = [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 20000]

    {:ok, response} =
      HTTPoison.request(
        :post,
        "https://testing.cms.fiuba.lambdaclass.com/upload",
        {:multipart,
         [
           {"file", pdf, {"form-data", [name: "files", filename: titulo_pdf ]},
            [{"Content-Type", "application/pdf"}]},
           {"type", "file/pdf"}
         ]},
        headers,
        options
      )
      |> HTTPoison.Retry.autoretry(
        max_attempts: 20,
        wait: 20000,
        include_404s: false,
        retry_unknown_errors: false
      )

    # response_body = response_imagen.body
    # {:ok, response_body_map} = JSON.decode(response_body)
    # {:ok, id_imagen} = Map.fetch(response_body_map |> Enum.at(0), "id")

    # id_imagen
    response
  end


  def pdfs do

    titulos_pdf = cargar_titulos_pdfs()

    Enum.map(
      titulos_pdf,
      fn titulo ->
        id_file = titulo |> Enum.at(0) |> cargar_pdf()
      end
    )
  end

end