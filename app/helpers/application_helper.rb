module ApplicationHelper

  def category_frequency(arr, category_name)
    flag = false
    arr.each do |k|
      if k["name"] == category_name
        k["count"] = k["count"] + 1
        flag = true
      end
    end
    arr << {"name" => category_name, "count" => 1} unless flag
    return arr
  end

end
