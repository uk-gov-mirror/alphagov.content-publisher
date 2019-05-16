# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# Rails.application.config.content_security_policy do |policy|
#   policy.default_src :self, :https
#   policy.font_src    :self, :https, :data
#   policy.img_src     :self, :https, :data
#   policy.object_src  :none
#   policy.script_src  :self, :https
#   policy.style_src   :self, :https

#   # Specify URI for violation reports
#   # policy.report_uri "/csp-violation-report-endpoint"
# end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true

Rails.application.config.content_security_policy do |policy|
  GOVUK_DOMAINS = %w(*.publishing.service.gov.uk).freeze

  GOOGLE_ANALYTICS_DOMAINS = %w(www.google-analytics.com ssl.google-analytics.com stats.g.doubleclick.net).freeze

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/default-src
  policy.default_src :https, :self, *GOVUK_DOMAINS

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/img-src
  policy.img_src :self,
                 :data,  # Base64 encoded images
                 *GOVUK_DOMAINS,
                 *GOOGLE_ANALYTICS_DOMAINS, # Analytics use tracking pixels
                 # Some images still links to an old domain we used to use
                 "assets.digital.cabinet-office.gov.uk"

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src
  policy.script_src :self,
                    *GOVUK_DOMAINS,
                    *GOOGLE_ANALYTICS_DOMAINS,
                    # Allow JSONP call to Verify to check whether the user is logged in
                    "www.signin.service.gov.uk",
                    # Allow YouTube Embeds (Govspeak turns YouTube links into embeds)
                    "*.ytimg.com",
                    "www.youtube.com"

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/style-src
  policy.style_src :self,
                   *GOVUK_DOMAINS

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/connect-src
  policy.connect_src :self,
                     *GOVUK_DOMAINS,
                     *GOOGLE_ANALYTICS_DOMAINS,
                     # Allow connecting to web chat from HMRC contact pages
                    "www.tax.service.gov.uk",
                    # Allow connecting to Verify to check whether the user is logged in
                    "www.signin.service.gov.uk"

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/object-src
  policy.object_src :none

  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/object-src
  policy.frame_src "www.youtube.com"

  # Generate a nonce that can be used for inline scripts
  Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

  Rails.application.config.content_security_policy_report_only = true
end
