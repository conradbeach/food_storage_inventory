Madmin.site_name = "Food Storage"

Rails.application.config.to_prepare do
  Madmin.menu.before_render do
    add label: "Background Jobs", url: "/jobs", position: 100
  end
end
