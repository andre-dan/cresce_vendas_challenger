class TestJob < ApplicationJob
  queue_as :default

  def perform(name)
    puts "Executando o job para #{name}"
  end
end
