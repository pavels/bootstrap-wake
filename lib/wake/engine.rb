module Wake
  class Engine < ::Rails::Engine
    
#    isolate_namespace Wake # this is not a mountable app

    # initializer "static assets" do |app|
    #   app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    # end

  end
end

