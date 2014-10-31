class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.json :categories

      t.timestamps
    end
  end
end
