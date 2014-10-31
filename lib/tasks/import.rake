namespace :db do
  task populate: :environment do
    Product.delete_all
    Category.delete_all
    data = JSON.parse(File.read("public/drinks.json"))
    records = data["products"]
    records.each do |product|
      Product.create(name: product["name"], categories: [product["categories"].first])
      product["categories"].each do |category|
          Category.create(name: category["name"], key: category["id"]) unless Category.find_by_key(category["id"])
      end
    end
  end

  task populate_metric: :environment do
    Metric.delete_all
    data = JSON.parse(File.read("public/drinks_test.json"))
    records = data["products"]
    records.each do |product|
      Metric.create(name: product["name"], categories: product["categories"].first)
    end
  end
end
