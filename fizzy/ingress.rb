# Addon Home Assistant : support Ingress (sous-chemin dynamique).
#
# La passerelle Ingress transmet les requetes sans le prefixe
# (/api/hassio_ingress/<session>) et ajoute l'en-tete X-Ingress-Path.
# Sans traitement, Rails genere des URLs absolues (redirections, liens,
# assets) qui font sortir du panneau HA -> 404.
#
# Actif uniquement quand l'en-tete est present (acces direct inchange) :
#  - restaure le prefixe dans SCRIPT_NAME (url_for, redirect_to, formulaires),
#  - relativise les redirections Location (reste dans l'iframe, quel que
#    soit host/port vus par Rails),
#  - prefixe les chemins absolus dans le HTML/JSON (href/src/action/url()).
class FizzyIngress
  PREFIX_HEADER = "HTTP_X_INGRESS_PATH".freeze
  REWRITABLE_TYPES = %r{\b(html|json)\b}i.freeze
  ATTR_PATTERN = %r{((?:href|src|action|formaction|srcset|poster|content|data-[\w-]+)\s*=\s*["'])/(?!/)}i.freeze
  CSS_URL_PATTERN = %r{url\(\s*/(?!/)}i.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    prefix = ingress_prefix(env)
    env["SCRIPT_NAME"] = prefix if prefix

    status, headers, body = @app.call(env)
    if prefix
      begin
        rewrite_location!(headers, prefix)
        rewritten = rewrite_body(status, headers, body, prefix)
        return rewritten if rewritten
      rescue => error
        warn("[fizzy-ingress] passthrough (#{error.class}: #{error.message})")
      end
    end
    [status, headers, body]
  end

  private

  def ingress_prefix(env)
    raw = env[PREFIX_HEADER].to_s.strip
    return nil if raw.empty? || raw == "/"
    raw = raw.chomp("/")
    return nil unless raw.start_with?("/")
    raw
  end

  # https://hote<PREFIXE>/chemin -> /<PREFIXE>/chemin (relatif : le navigateur
  # reste dans l'iframe, sans dependre du host/port percus par Rails).
  # Ne touche que nos propres URLs (le chemin commence par le prefixe).
  def rewrite_location!(headers, prefix)
    location = headers["Location"]
    return unless location.is_a?(String)
    escaped = Regexp.escape(prefix)
    if location =~ %r{\Ahttps?://[^/]+(#{escaped}/\S*)\z}
      headers["Location"] = Regexp.last_match(1)
    elsif location =~ %r{\Ahttps?://[^/]+(#{escaped})\z}
      headers["Location"] = prefix
    end
  end

  # Prefixe les chemins absolus dans les pages HTML/JSON. Retourne le nouveau
  # triplet ou nil (laisser la reponse d'origine).
  def rewrite_body(status, headers, body, prefix)
    return nil unless status == 200
    return nil unless headers["Content-Type"].to_s =~ REWRITABLE_TYPES
    return nil if headers["Content-Encoding"]

    chunks = []
    body.each { |part| chunks << part.to_s }
    html = chunks.join
    return nil if html.empty?

    rewritten = html
      .gsub(ATTR_PATTERN) { "#{Regexp.last_match(1)}#{prefix}/" }
      .gsub(CSS_URL_PATTERN) { "url(#{prefix}/" }
    return nil if rewritten == html

    body.close if body.respond_to?(:close)
    headers.delete("ETag")
    headers["Content-Length"] = rewritten.bytesize.to_s
    [status, headers, [rewritten]]
  end
end

Rails.application.config.middleware.unshift(FizzyIngress)
