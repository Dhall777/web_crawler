defmodule WebCrawler.Crawler do
  require HTTPoison
  require Floki

  # send GET request to our URL 
  def fetch_page(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "HTTP request failed with status code #{status_code}"}
      {:error, reason} ->
        {:error, "HTTP request failed with reason #{reason}"}
    end
  end

  # parse HTML content
  def parse_html(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        # navigate and extract data from the document (thanks Floki)
        # get all links:
        links = Floki.find(document, "a")

        {:ok, links}
      {:error, reason} ->
        {:error, "HTML parsing failed with reason #{reason}"}
    end
  end

  def crawl(url, depth) when depth <= 0, do: {:ok, []}
  def crawl(url, depth) do
    case fetch_page(url) do
      {:ok, body} ->
        case parse_html(body) do
          {:ok, links} ->
            # Process the links or data as needed
            IO.puts("Crawling #{url} and found #{length(links)} links.")

            # Filter and crawl internal links
            internal_links = filter_internal_links(links, url)
            crawl_links(internal_links, depth - 1)

          {:error, _reason} ->
            IO.puts("Failed to parse HTML for #{url}")
        end

      {:error, _reason} ->
        IO.puts("Failed to fetch #{url}")
    end
  end

  # Helper function to filter internal links
  defp filter_internal_links(links, base_url) do
    domain = get_domain(base_url)
    Enum.filter(links, fn link ->
      case link do
        %{"href" => href} when is_binary(href) ->
          case URI.parse(href) do
            %URI{host: host} when is_binary(host) and host == domain -> true
            _ -> false
          end
        _ ->
          false # Invalid link format, exclude this link
      end
    end)
  end

  # Helper function to extract the domain from a URL
  defp get_domain(url) do
    URI.parse(url).host
  end

  defp crawl_links([], _depth), do: {:ok, []}
  defp crawl_links([link | rest], depth) do
    crawl(link, depth)
    crawl_links(rest, depth)
  end
end
