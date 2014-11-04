#Demoapp

###Start elasticsearch

    sudo service elasticsearch start

Now you can access it on [localhost:9200](http://localhost:9200)
This is where you can find [Sense](http://localhost:9200/_plugin/marvel/sense/index.html).

###Populate database

In terminal:

    rake db:populate

###Create index in Sense

One way to create index is from Rails console:

    Product.__elasticsearch__.create_index! force: true 

However, if we need additional settings, like in this case we do, this should be done in Sense:


    PUT /products
    {
        "settings": {
            "analysis": {
              "filter": {
                  "my_stopwords": {
                      "type":       "stop",
                      "stopwords": [ "l", "g" ]
                  },
                 "filter_amount": {
                      "type": "pattern_replace",
                      "pattern": "[\\d]+([\\.,][\\d]+)?",
                      "replacement": ""
                  }
                },
                "analyzer": {
                    "my_analyzer": {
                        "type":         "custom",
                        "tokenizer":    "standard",
                        "filter":       [ "lowercase", "my_stopwords", "filter_amount"]
                }}
      }}}

This creates index products and sets the analyzer.

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

Test it in Sense:

    GET /products/_analyze?analyzer=my_analyzer&text=Kafa 1,95 l 200 g

It should return:

    {
     "tokens": [
        {
           "token": "kafa",
           "start_offset": 0,
           "end_offset": 4,
           "type": "<ALPHANUM>",
           "position": 1
        },
        {
           "token": "",
           "start_offset": 5,
           "end_offset": 9,
           "type": "<NUM>",
           "position": 2
        },
        {
           "token": "",
           "start_offset": 12,
           "end_offset": 15,
           "type": "<NUM>",
           "position": 4
        }
     ]
    }
###Populate products index

Then in terminal, run:

    bundle exec rake environment elasticsearch:import:all

###Test

In console:

    Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "alkohol"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').records.count

In Sense:

    GET products/_search
    {
      "query": {
        "fuzzy_like_this_field" : {
          "_all":  {
            "like_text": "alkohol",
            "analyzer": "my_analyzer"

          }
        }
      },
      "aggs" : {
        "categories" : {
            "nested" : {
                "path" : "categories"
            },
            "aggs": {
               "name_count" : {
                 "terms" : { 
                   "field" : "categories.id"
                 }
              }
            }
          }
       }
    }


###Get the most similar category

    response=Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "alkohol", "analyzer": "my_analyzer"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').response

    response.aggregations["categories"]["group_by_categories"]["buckets"].first["key"]

    key = response.aggregations["categories"]["group_by_categories"]["buckets"][0..5].map {|x| x["key"]}.map{|n| Category.find_by(key: n).name}



