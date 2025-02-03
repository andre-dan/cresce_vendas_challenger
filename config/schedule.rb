require "sidekiq-cron"

Sidekiq::Cron::Job.destroy("SyncProductsJob") # remove para recriar com novo cron
Sidekiq::Cron::Job.create(name: "SyncProductsJob", cron: "0 0,12 * * *", class: "SyncProductsJob")

Sidekiq::Cron::Job.destroy("SyncStoksJob") # remove para recriar com novo cron
Sidekiq::Cron::Job.create(name: "SyncStoksJob", cron: "*/5 * * * *", class: "SyncStoksJob")

Sidekiq::Cron::Job.destroy("SyncPricesJob") # remove para recriar com novo cron
Sidekiq::Cron::Job.create(name: "SyncPricesJob", cron: "*/55 * * * *", class: "SyncPricesJob")

Sidekiq::Cron::Job.destroy("SyncOrdesJob") # remove para recriar com novo cron
Sidekiq::Cron::Job.create(name: "SyncOrdesJob", cron: "*/5 * * * *", class: "SyncOrdesJob")
