class Xwjdic < Padrino::Application
  register Padrino::Mailer
  register Padrino::Helpers
  register CompassInitializer
  
  ##
  # Application-specific configuration options
  #
  # set :public, "foo/bar"      # Location for static assets (default root/public)
  # set :default_builder, "foo" # Set a custom form builder (default 'StandardFormBuilder')
  # set :locale_path, "bar"     # Set path for I18n translations (default your_app/locales)
  # enable  :sessions           # Disabled by default
  # disable :flash              # Disables rack-flash (enabled by default if sessions)
  # disable :padrino_helpers    # Disables padrino markup helpers (enabled by default if present)
  # disable :padrino_mailer     # Disables padrino mailer (enabled by default if present)
  enable :sessions
  layout :layout
  set :haml, :format => :html5
end