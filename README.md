# Backend Challenge - Ruby on Rails

This is a Ruby on Rails backend application that integrates with external services to manage products, orders, and synchronization jobs.

## Technologies Used

- Ruby on Rails 8.0
- Sidekiq for background job processing
- Redis for job queues
- Active Storage for file handling
- Sqlite database

## Key Features

- Product synchronization with external API
- Order management system
- Price and stock synchronization
- Background job processing with Sidekiq
- Payment processing integration

## Setup

1. Clone the repository:
```bash
git clone https://github.com/andre-dan/cresce_vendas_challenger

entre na pasta do projeto rode o comando abaixo

rails db:setup

rails db:seeds

rails c

em outra janela do terminal rode o comando abaixo

bundle exec sidekiq

pode aguardar  o processo de sincronização dos produtos ou forçar a sincronização com o comando abaixo

SyncProductJob.perform_asyync