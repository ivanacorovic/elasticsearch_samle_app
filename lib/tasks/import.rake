namespace :db do

  task populate_products: :environment do
    Product.destroy_all
    Metric.destroy_all
    data = JSON.parse(File.read("public/food.json"))
    records = data["products"]
    metric = records.sample(100)
    metric.each do |m|
      records.delete(m)
      Metric.create(name: m["name"], categories: m["categories"].first)
    end
    records.each do |product|
      Product.create(name: product["name"], categories: [product["categories"].first])
    end
  end

  task populate_categories: :environment do
    Category.destroy_all
    Product.all.pluck("categories").each do |category|
      Category.create(name: category.first["name"], key: category.first["id"]) unless Category.find_by_key(category.first["id"])
    end
  end

  task populate_metric: :environment do
    Metric.delete_all
    i = 0
    while i < 100 do
      metric = Product.offset(rand(Product.count)).first
      Metric.create(name: metric.name, categories: metric.categories.first)
      Product.destroy(metric.id)
      i = i + 1
    end
  end

  task :populate_once => [
    :populate_products,
    :populate_categories
  ]

end
