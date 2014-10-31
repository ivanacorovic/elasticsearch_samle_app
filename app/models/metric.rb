class Metric < ActiveRecord::Base

  def self.score
    result = 0
    total = count
    find_each do |test|
      response=Product.search('{"query": {"fuzzy_like_this_field": {"_all": {"like_text": "' + "#{test.name}" + '"}}},"aggs": {"categories": {"nested": {"path": "categories"},"aggs": { "group_by_categories": { "terms": {"field": "categories.id"}}}}}}').response
      key = response.aggregations["categories"]["group_by_categories"]["buckets"][0..5].map {|x| x["key"]}.map{|n| Category.find_by(key: n).name}
      if key.find_index(test.categories["name"])
        puts test.categories["name"]
        result = result + 1
      end
    end
    return "Nasao za #{result}, nije za #{total - result}"
  end
end
