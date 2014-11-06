class Metric < ActiveRecord::Base

  def self.score
    result = 0
    found = []
    not_found = Metric.all.pluck("name")
    total = count
    find_each do |test|
      # response=Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "' + "#{test.name}" + '", "analyzer": "my_analyzer"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').response
      # key = response.aggregations["categories"]["group_by_categories"]["buckets"][0..3].map {|x| x["key"]}.map{|n| Category.find_by(key: n).name}
      
      response = Product.search('{"query": {"multi_match": {"query": "' + "#{test.name}" + '", "type": "cross_fields", "fields":[ "name", "categories.name^10"]}}}').response 
      key = response["hits"]["hits"].to_a[0..5].map {|x| x["_source"]["categories"].to_s.split.to_a[1].split("=")[1].to_i}.uniq.map{|n| Category.find_by(key: n).name unless Category.find_by(key: n).nil?} unless response["hits"]["hits"].nil?
      if key.find_index(test.categories["name"])
        result = result + 1
        found << test.name
        not_found.delete(test.name)
      end
    end
    return "Nasao za #{result}, nije za #{total - result}, nadjeni: #{found}, nisu nadjeni #{not_found}"
  end

  def self.suggest_categories_for(name)
    response = Product.search('{"query": {"multi_match": {"query": "' + "#{name}" + '", "type": "cross_fields", "fields":[ "name", "categories.name^10"]}}}').response 
    key = response["hits"]["hits"].to_a[0..5].map {|x| x["_source"]["categories"].to_s.split.to_a[1].split("=")[1].to_i}.uniq.map{|n| Category.find_by(key: n).name unless Category.find_by(key: n).nil?} unless response["hits"]["hits"].nil?
    return key
  end
end
