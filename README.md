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
                      "stopwords": [ "l", "g", "kg", "ml" ]
                  },
                 "filter_amount": {
                      "type": "pattern_replace",
                      "pattern": "[\\d]+([\\.,][\\d]+)?[\\w]*",
                      "replacement": ""
                  }
                },
                "analyzer": {
                    "default_search": {
                        "type":         "custom",
                        "tokenizer":    "standard",
                        "filter":       [ "lowercase", "my_stopwords", "filter_amount"]
                }}
      }}}

This creates index products and sets default search analyzer.

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

    GET /products/_analyze?analyzer=default_search&text=Kafa 1,95 l 200 g

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

This will add all the models to Elasticsearch index.
If you want just products:

    bundle exec rake environment elasticsearch:import:model CLASS=Product

The latter one is what we need here.

###Test

In console:

    Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "alkohol"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').records.count

In Sense:

    GET   products/_count


    GET products/_search
    {
      "query": {
        "fuzzy_like_this_field" : {
          "_all":  {
            "like_text": "Ledeni Ä\\u008Daj 1 l limun Podravka"
            //this is where you'd put "analyzer": "some_analyzer"
          }
        }
      },
      "aggs" : {
        "categories" : {
            "nested" : {
                "path" : "categories"
            },
            "aggs": {
               "categories_count" : {
                 "terms" : { 
                   "field" : "categories.id"
                 }
              }
            }
          }
       }
    }


###Get the most similar category

In Sense:

    GET /products/_search
    {
        "query": {
            "multi_match": {
                "query":   "tic tac jabuka",
                "type":        "cross_fields",
                "fields":      [ "name", "categories.name^10"]
            }
        }
    }

    categories.name is boosted up to 10.

In Rails:

    def self.suggest_categories_for(name)
      response = search('{"query": {"multi_match": {"query": "' + "#{name}" + '", "type": "cross_fields", "fields":[ "name", "categories.name^10"]}}}').response 
      key = response["hits"]["hits"].to_a[0..5].map {|x| x["_source"]["categories"].to_s.split.to_a[1].split("=")[1].to_i}.uniq.map{|n| Category.find_by(key: n).name unless Category.find_by(key: n).nil?} unless response["hits"]["hits"].nil?
      return key
    end

Since our analyzer is default_search, it is included by default.

We call this method like this:

    Product.suggest_categories_for("Product name we'd like to categorize")

