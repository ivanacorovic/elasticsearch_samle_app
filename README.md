#Demoapp


###Populate database

In terminal:

    rake db:populate

###Create index in Sense

In Rails console:

    Product.__elasticsearch__.create_index! force: true

This creates index products.

###Create mapping for products index

In Sense:
  
    PUT products/_mapping/product
    {
     "product": {
        "properties": {
          "categories": {
            "type": "nested",
            "properties": {
              "id": {
                "type": "long"
              },
              "name": {
                "type": "string"
              }
            }
          },
          "id": {
            "type": "long"
          },
          "name": {
            "type": "string"
          }
        }
      }
    }

###Populate products index

Then in terminal, run:

    bundle exec rake environment elasticsearch:import:all

###Test

    Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "alkohol"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').records.count

###Get the most simular category

    response=Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "alkohol"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').response

    response.aggregations["categories"]["group_by_categories"]["buckets"].first["key"]

    key = response.aggregations["categories"]["group_by_categories"]["buckets"][0..5].map {|x| x["key"]}.map{|n| Category.find_by(key: n).name}



