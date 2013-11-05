class CreateFares < ActiveRecord::Migration
  def change
    create_table :fares do |t|
      t.string :fare_type
      t.string :unit
      t.float :amount
      t.string :base_units
      t.float :base_cost
      t.string :description
      t.boolean :voluntary
      t.integer :service_id

      t.timestamps
    end
  end
end
