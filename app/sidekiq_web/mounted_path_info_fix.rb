# Rack wrapper for apps mounted in config/routes.rb.
#
# The routing-filter gem sets PATH_INFO back to the full request path
# before Rails calls a mounted app (see
# routing_filter/adapters/routers/journey.rb). The app then sees
# SCRIPT_NAME "/sidekiq/uk" and PATH_INFO "/sidekiq/uk/queues", and it
# cannot find its own routes. This wrapper removes SCRIPT_NAME from the
# start of PATH_INFO again.
class MountedPathInfoFix
  def initialize(app)
    @app = app
  end

  def call(env)
    script_name = env["SCRIPT_NAME"].to_s
    path_info = env["PATH_INFO"].to_s

    if script_name.present?
      if path_info == script_name
        env["PATH_INFO"] = "/"
      elsif path_info.start_with?("#{script_name}/")
        env["PATH_INFO"] = path_info.delete_prefix(script_name)
      end
    end

    @app.call(env)
  end
end
