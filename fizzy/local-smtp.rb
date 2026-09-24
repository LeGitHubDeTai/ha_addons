# Addon Home Assistant : SMTP local (Mailpit) sans authentification.
#
# config/environments/production.rb force `authentication: "plain"` par défaut,
# ce qui fait échouer la livraison sans identifiants
# ("SMTP-AUTH requested but missing user name").
# Cet initializer annule l'auth uniquement en mode SMTP local.
if ENV["FIZZY_LOCAL_SMTP"] == "true"
  Rails.application.config.action_mailer.smtp_settings ||= {}
  Rails.application.config.action_mailer.smtp_settings[:authentication] = nil
end
