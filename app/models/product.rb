class Product < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  def self.suggest_categories_for(name)
    response = search('{"query": {"multi_match": {"query": "' + "#{name}" + '", "type": "cross_fields", "fields":[ "name", "categories.name^10"]}}}').response 
    key = response["hits"]["hits"].to_a[0..5].map {|x| x["_source"]["categories"].to_s.split.to_a[1].split("=")[1].to_i}.uniq.map{|n| Category.find_by(key: n).name unless Category.find_by(key: n).nil?} unless response["hits"]["hits"].nil?
    return key
  end

end
