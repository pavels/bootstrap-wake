class CreateThings < ActiveRecord::Migration
  def change
    create_table :things do |t|
      t.integer :int
      t.string :str

      t.timestamps
    end
  end
end
